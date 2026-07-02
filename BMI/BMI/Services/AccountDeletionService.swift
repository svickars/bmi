import CloudKit
import Foundation
import SwiftData

enum AccountDeletionError: LocalizedError {
    case missingAppleUserID
    case cloudDeletionFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAppleUserID:
            "Could not determine your Apple account identifier."
        case .cloudDeletionFailed(let message):
            "Could not delete cloud data: \(message)"
        }
    }
}

@MainActor
final class AccountDeletionService {
    private let container: CKContainer
    private var publicDatabase: CKDatabase { container.publicCloudDatabase }

    init(container: CKContainer = CKContainer(identifier: CloudKitSchema.containerIdentifier)) {
        self.container = container
    }

    func deleteAccount(for user: UserProfile, in context: ModelContext) async throws {
        guard let appleUserID = user.appleUserID else {
            throw AccountDeletionError.missingAppleUserID
        }

        try await deleteAuthoredReports(appleUserID: appleUserID)
        try await deleteRecords(
            recordType: CloudKitSchema.RecordType.friendConnection,
            predicate: NSPredicate(
                format: "%K == %@ OR %K == %@",
                CloudKitSchema.FriendConnection.fromAppleUserID, appleUserID,
                CloudKitSchema.FriendConnection.toAppleUserID, appleUserID
            )
        )
        try await deleteRecords(
            recordType: CloudKitSchema.RecordType.userNotification,
            predicate: NSPredicate(
                format: "%K == %@ OR %K == %@",
                CloudKitSchema.UserNotification.recipientAppleUserID, appleUserID,
                CloudKitSchema.UserNotification.actorAppleUserID, appleUserID
            )
        )
        try await deleteRecords(
            recordType: CloudKitSchema.RecordType.reportReaction,
            predicate: NSPredicate(format: "%K == %@", CloudKitSchema.ReportReaction.reactorAppleUserID, appleUserID)
        )

        try await publicDatabase.deleteRecord(withID: CKRecord.ID(recordName: "user.\(appleUserID)"))

        clearLocalData(for: user, in: context)
    }

    private func deleteAuthoredReports(appleUserID: String) async throws {
        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.PublicReport.authorAppleUserID, appleUserID)
        let reports = try await fetchRecordIDs(recordType: CloudKitSchema.RecordType.publicReport, predicate: predicate)

        for recordID in reports {
            if let reportID = recordID.recordName.split(separator: ".").last {
                try await deleteRecords(
                    recordType: CloudKitSchema.RecordType.publicReportPhoto,
                    predicate: NSPredicate(format: "%K == %@", CloudKitSchema.PublicReportPhoto.reportID, String(reportID))
                )
                try await deleteRecords(
                    recordType: CloudKitSchema.RecordType.reportReaction,
                    predicate: NSPredicate(format: "%K == %@", CloudKitSchema.ReportReaction.reportID, String(reportID))
                )
                try await deleteRecords(
                    recordType: CloudKitSchema.RecordType.userNotification,
                    predicate: NSPredicate(format: "%K == %@", CloudKitSchema.UserNotification.reportID, String(reportID))
                )
            }
            try await publicDatabase.deleteRecord(withID: recordID)
        }
    }

    private func deleteRecords(recordType: String, predicate: NSPredicate) async throws {
        let recordIDs = try await fetchRecordIDs(recordType: recordType, predicate: predicate)
        guard !recordIDs.isEmpty else { return }

        for recordID in recordIDs {
            try await publicDatabase.deleteRecord(withID: recordID)
        }
    }

    private func fetchRecordIDs(recordType: String, predicate: NSPredicate) async throws -> [CKRecord.ID] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: 200)
        return results.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return record.recordID
        }
    }

    private func clearLocalData(for user: UserProfile, in context: ModelContext) {
        let userID = user.id

        if let reports = try? context.fetch(FetchDescriptor<BigMacReport>()) {
            reports.filter { $0.author?.id == userID || $0.authorAppleUserID == user.appleUserID }.forEach {
                context.delete($0)
            }
        }

        if let links = try? context.fetch(FetchDescriptor<FriendLink>()) {
            links.filter { $0.ownerAppleUserID == user.appleUserID }.forEach { context.delete($0) }
        }

        if let notifications = try? context.fetch(FetchDescriptor<UserNotification>()) {
            notifications.filter { $0.recipientAppleUserID == user.appleUserID }.forEach { context.delete($0) }
        }

        if let reactions = try? context.fetch(FetchDescriptor<ReportReaction>()) {
            reactions.filter { $0.reactorAppleUserID == user.appleUserID }.forEach { context.delete($0) }
        }

        context.delete(user)
        try? context.save()
    }
}
