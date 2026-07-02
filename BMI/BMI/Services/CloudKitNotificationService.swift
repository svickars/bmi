import CloudKit
import Foundation
import SwiftData
import UserNotifications

@MainActor
final class CloudKitNotificationService: ObservableObject {
    static let shared = CloudKitNotificationService()

    private let container: CKContainer
    private var publicDatabase: CKDatabase { container.publicCloudDatabase }
    private let activityNotifications = ActivityNotificationService()

    init(container: CKContainer = CKContainer(identifier: CloudKitSchema.containerIdentifier)) {
        self.container = container
    }

    func requestPermissionAndRegister() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func configureSubscriptions(for profile: UserProfile) async throws {
        guard let appleUserID = profile.appleUserID else { return }

        try await saveFriendRequestSubscription(for: appleUserID)
        try await saveActivitySubscription(for: appleUserID)
    }

    func handleRemoteNotification(
        userInfo: [AnyHashable: Any],
        modelContext: ModelContext,
        currentUser: UserProfile?,
        syncCoordinator: SyncCoordinator
    ) async {
        guard let ckNotification = CKNotification(fromRemoteNotificationDictionary: userInfo),
              let currentUser,
              let appleUserID = currentUser.appleUserID else { return }

        let settings = (try? modelContext.fetch(FetchDescriptor<AppSettings>()))?.first

        do {
            if let queryNotification = ckNotification as? CKQueryNotification,
               let recordID = queryNotification.recordID {
                switch queryNotification.subscriptionID {
                case "friend-requests.\(appleUserID)":
                    try await syncCoordinator.friendLinks.syncFriendConnections(for: currentUser, in: modelContext)
                    await postFriendRequestNotifications(modelContext: modelContext, currentUser: currentUser)
                case "activity.\(appleUserID)":
                    _ = try await activityNotifications.fetchNotifications(for: currentUser, into: modelContext)
                    if let record = try? await publicDatabase.record(for: recordID) {
                        await postActivityNotification(from: record, settings: settings)
                    }
                default:
                    break
                }
            }

            if settings?.enablePublicSync == true {
                await syncCoordinator.syncAll(modelContext: modelContext, currentUser: currentUser, settings: settings ?? AppSettingsStore.current(in: modelContext))
            }
        } catch {
            syncCoordinator.lastError = error.localizedDescription
        }
    }

    func deliverPendingNotifications(
        for currentUser: UserProfile,
        in modelContext: ModelContext,
        settings: AppSettings?
    ) async {
        guard let appleUserID = currentUser.appleUserID else { return }

        let descriptor = FetchDescriptor<UserNotification>(
            predicate: #Predicate {
                $0.recipientAppleUserID == appleUserID && $0.isRead == false
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let unread = (try? modelContext.fetch(descriptor)) ?? []
        for notification in unread.prefix(3) {
            await postLocalNotification(for: notification, settings: settings)
        }
    }

    private func saveFriendRequestSubscription(for appleUserID: String) async throws {
        let subscriptionID = "friend-requests.\(appleUserID)"
        try? await publicDatabase.deleteSubscription(withID: subscriptionID)

        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            CloudKitSchema.FriendConnection.toAppleUserID, appleUserID,
            CloudKitSchema.FriendConnection.status, FriendLinkStatus.pendingOutgoing.rawValue
        )

        let subscription = CKQuerySubscription(
            recordType: CloudKitSchema.RecordType.friendConnection,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )

        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        info.shouldBadge = true
        subscription.notificationInfo = info

        try await publicDatabase.save(subscription)
    }

    private func saveActivitySubscription(for appleUserID: String) async throws {
        let subscriptionID = "activity.\(appleUserID)"
        try? await publicDatabase.deleteSubscription(withID: subscriptionID)

        let predicate = NSPredicate(
            format: "%K == %@",
            CloudKitSchema.UserNotification.recipientAppleUserID,
            appleUserID
        )

        let subscription = CKQuerySubscription(
            recordType: CloudKitSchema.RecordType.userNotification,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation]
        )

        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        info.shouldBadge = true
        subscription.notificationInfo = info

        try await publicDatabase.save(subscription)
    }

    private func postActivityNotification(from record: CKRecord, settings: AppSettings?) async {
        guard record.recordType == CloudKitSchema.RecordType.userNotification,
              let typeRaw = record[CloudKitSchema.UserNotification.typeRaw] as? String,
              let type = ActivityNotificationType(rawValue: typeRaw),
              settings?.allows(type) != false else { return }

        let title = record[CloudKitSchema.UserNotification.title] as? String ?? "BMI Update"
        let body = record[CloudKitSchema.UserNotification.body] as? String ?? ""
        let notificationID = record[CloudKitSchema.UserNotification.notificationID] as? String ?? UUID().uuidString
        let reportID = record[CloudKitSchema.UserNotification.reportID] as? String ?? ""

        await post(
            title: title,
            body: body,
            identifier: "activity.\(notificationID)",
            userInfo: ["route": "report", "reportID": reportID]
        )
    }

    private func postLocalNotification(for notification: UserNotification, settings: AppSettings?) async {
        guard settings?.allows(notification.type) != false else { return }
        await post(
            title: notification.title,
            body: notification.body,
            identifier: "activity.\(notification.id.uuidString)",
            userInfo: ["route": "report", "reportID": notification.reportID.uuidString]
        )
    }

    private func postFriendRequestNotifications(modelContext: ModelContext, currentUser: UserProfile) async {
        guard let appleUserID = currentUser.appleUserID else { return }

        let descriptor = FetchDescriptor<FriendLink>(
            predicate: #Predicate {
                $0.ownerAppleUserID == appleUserID && $0.statusRaw == "pendingIncoming"
            }
        )
        let incoming = (try? modelContext.fetch(descriptor)) ?? []
        guard let latest = incoming.first else { return }

        await post(
            title: "New Friend Request",
            body: "\(latest.friendDisplayName) (@\(latest.friendUsername)) wants to connect on BMI.",
            identifier: "friend-request.\(latest.id.uuidString)",
            userInfo: ["route": "friends"]
        )
    }

    private func post(title: String, body: String, identifier: String, userInfo: [String: String] = [:]) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}

import UIKit
