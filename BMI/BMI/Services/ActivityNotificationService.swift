import CloudKit
import Foundation
import SwiftData

@MainActor
final class ActivityNotificationService: ObservableObject {
    private let container: CKContainer
    private var publicDatabase: CKDatabase { container.publicCloudDatabase }

    init(container: CKContainer = CKContainer(identifier: CloudKitSchema.containerIdentifier)) {
        self.container = container
    }

    func fanOutReportNotifications(
        for report: BigMacReport,
        author: UserProfile,
        in context: ModelContext
    ) async throws {
        guard let authorAppleUserID = author.appleUserID else { return }

        var recipients = Set<String>()

        for taggedID in report.taggedFriendAppleUserIDs where taggedID != authorAppleUserID {
            try await createNotification(
                type: .taggedInReport,
                recipientAppleUserID: taggedID,
                report: report,
                actor: author
            )
            recipients.insert(taggedID)
        }

        let friends = acceptedFriendAppleUserIDs(for: authorAppleUserID, in: context)
        for friendAppleUserID in friends where friendAppleUserID != authorAppleUserID {
            guard !recipients.contains(friendAppleUserID) else { continue }
            try await createNotification(
                type: .friendReport,
                recipientAppleUserID: friendAppleUserID,
                report: report,
                actor: author
            )
        }
    }

    func notifyReaction(
        on report: BigMacReport,
        reactor: UserProfile,
        emoji: String
    ) async throws {
        guard let authorAppleUserID = report.authorAppleUserID,
              let reactorAppleUserID = reactor.appleUserID,
              authorAppleUserID != reactorAppleUserID else { return }

        try await createNotification(
            type: .reaction,
            recipientAppleUserID: authorAppleUserID,
            report: report,
            actor: reactor,
            reactionEmoji: emoji
        )
    }

    func fetchNotifications(for user: UserProfile, into context: ModelContext) async throws -> Int {
        guard let appleUserID = user.appleUserID else { return 0 }

        let predicate = NSPredicate(
            format: "%K == %@",
            CloudKitSchema.UserNotification.recipientAppleUserID,
            appleUserID
        )
        let query = CKQuery(recordType: CloudKitSchema.RecordType.userNotification, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.UserNotification.createdAt, ascending: false)]

        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: 100)
        var imported = 0

        for (_, result) in results {
            guard case .success(let record) = result,
                  let notificationIDString = record[CloudKitSchema.UserNotification.notificationID] as? String,
                  let notificationUUID = UUID(uuidString: notificationIDString),
                  let reportIDString = record[CloudKitSchema.UserNotification.reportID] as? String,
                  let reportUUID = UUID(uuidString: reportIDString) else { continue }

            let descriptor = FetchDescriptor<UserNotification>(
                predicate: #Predicate { $0.id == notificationUUID }
            )

            let notification: UserNotification
            if let existing = try? context.fetch(descriptor).first {
                notification = existing
            } else {
                notification = UserNotification(
                    id: notificationUUID,
                    recipientAppleUserID: appleUserID,
                    type: .friendReport,
                    reportID: reportUUID,
                    actorAppleUserID: "",
                    actorDisplayName: "",
                    actorUsername: "",
                    title: "",
                    body: ""
                )
                context.insert(notification)
                imported += 1
            }

            apply(record: record, to: notification)
        }

        try? context.save()
        return imported
    }

    func markRead(_ notification: UserNotification) async throws {
        notification.isRead = true
        guard let recordName = notification.cloudRecordName else { return }

        let record = try await publicDatabase.record(for: CKRecord.ID(recordName: recordName))
        record[CloudKitSchema.UserNotification.isRead] = true as CKRecordValue
        try await publicDatabase.save(record)
    }

    private func createNotification(
        type: ActivityNotificationType,
        recipientAppleUserID: String,
        report: BigMacReport,
        actor: UserProfile,
        reactionEmoji: String = ""
    ) async throws {
        let notificationID = UUID()
        let recordID = CKRecord.ID(recordName: "notification.\(recipientAppleUserID).\(notificationID.uuidString)")
        let record = CKRecord(recordType: CloudKitSchema.RecordType.userNotification, recordID: recordID)

        let (title, body) = copy(for: type, actor: actor, report: report, reactionEmoji: reactionEmoji)

        record[CloudKitSchema.UserNotification.notificationID] = notificationID.uuidString as CKRecordValue
        record[CloudKitSchema.UserNotification.recipientAppleUserID] = recipientAppleUserID as CKRecordValue
        record[CloudKitSchema.UserNotification.typeRaw] = type.rawValue as CKRecordValue
        record[CloudKitSchema.UserNotification.reportID] = report.id.uuidString as CKRecordValue
        record[CloudKitSchema.UserNotification.actorAppleUserID] = (actor.appleUserID ?? "") as CKRecordValue
        record[CloudKitSchema.UserNotification.actorDisplayName] = actor.displayName as CKRecordValue
        record[CloudKitSchema.UserNotification.actorUsername] = actor.username as CKRecordValue
        record[CloudKitSchema.UserNotification.title] = title as CKRecordValue
        record[CloudKitSchema.UserNotification.body] = body as CKRecordValue
        record[CloudKitSchema.UserNotification.reactionEmoji] = reactionEmoji as CKRecordValue
        record[CloudKitSchema.UserNotification.createdAt] = Date() as CKRecordValue
        record[CloudKitSchema.UserNotification.isRead] = false as CKRecordValue

        try await publicDatabase.save(record)
    }

    private func copy(
        for type: ActivityNotificationType,
        actor: UserProfile,
        report: BigMacReport,
        reactionEmoji: String
    ) -> (String, String) {
        switch type {
        case .friendReport:
            (
                "New Big Mac report",
                "\(actor.displayName) posted from \(report.locationName) · \(report.formattedCost)"
            )
        case .taggedInReport:
            (
                "You were tagged",
                "\(actor.displayName) tagged you in a report at \(report.locationName)"
            )
        case .reaction:
            (
                "New reaction",
                "\(actor.displayName) reacted \(reactionEmoji) to your report at \(report.locationName)"
            )
        }
    }

    private func apply(record: CKRecord, to notification: UserNotification) {
        notification.recipientAppleUserID = record[CloudKitSchema.UserNotification.recipientAppleUserID] as? String ?? notification.recipientAppleUserID
        notification.typeRaw = record[CloudKitSchema.UserNotification.typeRaw] as? String ?? notification.typeRaw
        if let reportIDString = record[CloudKitSchema.UserNotification.reportID] as? String,
           let reportUUID = UUID(uuidString: reportIDString) {
            notification.reportID = reportUUID
        }
        notification.actorAppleUserID = record[CloudKitSchema.UserNotification.actorAppleUserID] as? String ?? notification.actorAppleUserID
        notification.actorDisplayName = record[CloudKitSchema.UserNotification.actorDisplayName] as? String ?? notification.actorDisplayName
        notification.actorUsername = record[CloudKitSchema.UserNotification.actorUsername] as? String ?? notification.actorUsername
        notification.title = record[CloudKitSchema.UserNotification.title] as? String ?? notification.title
        notification.body = record[CloudKitSchema.UserNotification.body] as? String ?? notification.body
        notification.reactionEmoji = record[CloudKitSchema.UserNotification.reactionEmoji] as? String ?? notification.reactionEmoji
        notification.createdAt = record[CloudKitSchema.UserNotification.createdAt] as? Date ?? notification.createdAt
        notification.isRead = record[CloudKitSchema.UserNotification.isRead] as? Bool ?? notification.isRead
        notification.cloudRecordName = record.recordID.recordName
    }

    private func acceptedFriendAppleUserIDs(for ownerAppleUserID: String, in context: ModelContext) -> [String] {
        let descriptor = FetchDescriptor<FriendLink>(
            predicate: #Predicate {
                $0.ownerAppleUserID == ownerAppleUserID && $0.statusRaw == "accepted"
            }
        )
        return (try? context.fetch(descriptor).map(\.friendAppleUserID)) ?? []
    }
}
