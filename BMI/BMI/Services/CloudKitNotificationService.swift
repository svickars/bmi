import CloudKit
import Foundation
import SwiftData
import UserNotifications

@MainActor
final class CloudKitNotificationService: ObservableObject {
    static let shared = CloudKitNotificationService()

    private let container: CKContainer
    private var publicDatabase: CKDatabase { container.publicCloudDatabase }

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
        info.alertLocalizationKey = "%@ sent you a friend request on BMI"
        info.alertLocalizationArgs = [CloudKitSchema.FriendConnection.fromDisplayName]
        info.soundName = "default"
        info.shouldBadge = true
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info

        try await publicDatabase.save(subscription)
    }

    func handleRemoteNotification(
        userInfo: [AnyHashable: Any],
        modelContext: ModelContext,
        currentUser: UserProfile?,
        syncCoordinator: SyncCoordinator
    ) async {
        guard CKNotification(fromRemoteNotificationDictionary: userInfo) != nil,
              let currentUser else { return }

        do {
            try await syncCoordinator.friendLinks.syncFriendConnections(for: currentUser, in: modelContext)

            if let settings = try? modelContext.fetch(FetchDescriptor<AppSettings>()).first {
                await syncCoordinator.syncAll(modelContext: modelContext, currentUser: currentUser, settings: settings)
            }

            await postLocalFriendRequestReminder(modelContext: modelContext, currentUser: currentUser)
        } catch {
            syncCoordinator.lastError = error.localizedDescription
        }
    }

    private func postLocalFriendRequestReminder(modelContext: ModelContext, currentUser: UserProfile) async {
        guard let appleUserID = currentUser.appleUserID else { return }

        let descriptor = FetchDescriptor<FriendLink>(
            predicate: #Predicate {
                $0.ownerAppleUserID == appleUserID && $0.statusRaw == "pendingIncoming"
            }
        )
        let incoming = (try? modelContext.fetch(descriptor)) ?? []
        guard let latest = incoming.first else { return }

        let content = UNMutableNotificationContent()
        content.title = "New Friend Request"
        content.body = "\(latest.friendDisplayName) (@\(latest.friendUsername)) wants to connect on BMI."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "friend-request.\(latest.id.uuidString)",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
