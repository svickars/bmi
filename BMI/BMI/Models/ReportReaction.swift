import Foundation
import SwiftData

@Model
final class ReportReaction {
    var id: UUID
    var reportID: UUID
    var reactorAppleUserID: String
    var reactorDisplayName: String
    var reactionEmoji: String
    var createdAt: Date
    var cloudRecordName: String?

    init(
        id: UUID = UUID(),
        reportID: UUID,
        reactorAppleUserID: String,
        reactorDisplayName: String,
        reactionEmoji: String,
        createdAt: Date = .now,
        cloudRecordName: String? = nil
    ) {
        self.id = id
        self.reportID = reportID
        self.reactorAppleUserID = reactorAppleUserID
        self.reactorDisplayName = reactorDisplayName
        self.reactionEmoji = reactionEmoji
        self.createdAt = createdAt
        self.cloudRecordName = cloudRecordName
    }
}
