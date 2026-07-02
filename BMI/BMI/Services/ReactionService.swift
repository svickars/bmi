import CloudKit
import Foundation
import SwiftData

@MainActor
final class ReactionService: ObservableObject {
    private let container: CKContainer
    private var publicDatabase: CKDatabase { container.publicCloudDatabase }
    private let activityNotifications = ActivityNotificationService()

    init(container: CKContainer = CKContainer(identifier: CloudKitSchema.containerIdentifier)) {
        self.container = container
    }

    func reactions(for reportID: UUID, in context: ModelContext) -> [ReportReaction] {
        let descriptor = FetchDescriptor<ReportReaction>(
            predicate: #Predicate { $0.reportID == reportID },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func reactionSummary(for reportID: UUID, in context: ModelContext) -> [(emoji: String, count: Int)] {
        let reactions = reactions(for: reportID, in: context)
        let grouped = Dictionary(grouping: reactions, by: \.reactionEmoji)
        return grouped
            .map { (emoji: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    func currentUserReaction(for reportID: UUID, reactorAppleUserID: String?, in context: ModelContext) -> ReportReaction? {
        guard let reactorAppleUserID else { return nil }
        let descriptor = FetchDescriptor<ReportReaction>(
            predicate: #Predicate {
                $0.reportID == reportID && $0.reactorAppleUserID == reactorAppleUserID
            }
        )
        return try? context.fetch(descriptor).first
    }

    @discardableResult
    func toggleReaction(
        emoji: String,
        on report: BigMacReport,
        reactor: UserProfile,
        in context: ModelContext
    ) async throws -> ReportReaction? {
        guard let reactorAppleUserID = reactor.appleUserID else { return nil }

        if let existing = currentUserReaction(for: report.id, reactorAppleUserID: reactorAppleUserID, in: context) {
            if existing.reactionEmoji == emoji {
                try await removeReaction(existing, in: context)
                return nil
            }
            try await removeReaction(existing, in: context)
        }

        let reaction = ReportReaction(
            reportID: report.id,
            reactorAppleUserID: reactorAppleUserID,
            reactorDisplayName: reactor.displayName,
            reactionEmoji: emoji
        )
        context.insert(reaction)

        let recordID = CKRecord.ID(recordName: "reaction.\(report.id.uuidString).\(reactorAppleUserID)")
        let record = CKRecord(recordType: CloudKitSchema.RecordType.reportReaction, recordID: recordID)
        record[CloudKitSchema.ReportReaction.reactionID] = reaction.id.uuidString as CKRecordValue
        record[CloudKitSchema.ReportReaction.reportID] = report.id.uuidString as CKRecordValue
        record[CloudKitSchema.ReportReaction.reactorAppleUserID] = reactorAppleUserID as CKRecordValue
        record[CloudKitSchema.ReportReaction.reactorDisplayName] = reactor.displayName as CKRecordValue
        record[CloudKitSchema.ReportReaction.reactionEmoji] = emoji as CKRecordValue
        record[CloudKitSchema.ReportReaction.createdAt] = reaction.createdAt as CKRecordValue

        let saved = try await publicDatabase.save(record)
        reaction.cloudRecordName = saved.recordID.recordName

        try await activityNotifications.notifyReaction(on: report, reactor: reactor, emoji: emoji)
        try? context.save()
        return reaction
    }

    func syncReactions(for reportID: UUID, into context: ModelContext) async throws {
        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.ReportReaction.reportID, reportID.uuidString)
        let query = CKQuery(recordType: CloudKitSchema.RecordType.reportReaction, predicate: predicate)
        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: 100)

        for (_, result) in results {
            guard case .success(let record) = result,
                  let reactionIDString = record[CloudKitSchema.ReportReaction.reactionID] as? String,
                  let reactionUUID = UUID(uuidString: reactionIDString) else { continue }

            let descriptor = FetchDescriptor<ReportReaction>(
                predicate: #Predicate { $0.id == reactionUUID }
            )

            let reaction: ReportReaction
            if let existing = try? context.fetch(descriptor).first {
                reaction = existing
            } else {
                reaction = ReportReaction(
                    id: reactionUUID,
                    reportID: reportID,
                    reactorAppleUserID: "",
                    reactorDisplayName: "",
                    reactionEmoji: "❤️"
                )
                context.insert(reaction)
            }

            reaction.reportID = reportID
            reaction.reactorAppleUserID = record[CloudKitSchema.ReportReaction.reactorAppleUserID] as? String ?? reaction.reactorAppleUserID
            reaction.reactorDisplayName = record[CloudKitSchema.ReportReaction.reactorDisplayName] as? String ?? reaction.reactorDisplayName
            reaction.reactionEmoji = record[CloudKitSchema.ReportReaction.reactionEmoji] as? String ?? reaction.reactionEmoji
            reaction.createdAt = record[CloudKitSchema.ReportReaction.createdAt] as? Date ?? reaction.createdAt
            reaction.cloudRecordName = record.recordID.recordName
        }

        try? context.save()
    }

    private func removeReaction(_ reaction: ReportReaction, in context: ModelContext) async throws {
        if let recordName = reaction.cloudRecordName {
            try await publicDatabase.deleteRecord(withID: CKRecord.ID(recordName: recordName))
        }
        context.delete(reaction)
        try? context.save()
    }
}
