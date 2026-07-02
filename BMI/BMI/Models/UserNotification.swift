import Foundation
import SwiftData

@Model
final class UserNotification {
    var id: UUID
    var recipientAppleUserID: String
    var typeRaw: String
    var reportID: UUID
    var actorAppleUserID: String
    var actorDisplayName: String
    var actorUsername: String
    var title: String
    var body: String
    var reactionEmoji: String
    var createdAt: Date
    var isRead: Bool
    var cloudRecordName: String?

    var type: ActivityNotificationType {
        get { ActivityNotificationType(rawValue: typeRaw) ?? .friendReport }
        set { typeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        recipientAppleUserID: String,
        type: ActivityNotificationType,
        reportID: UUID,
        actorAppleUserID: String,
        actorDisplayName: String,
        actorUsername: String,
        title: String,
        body: String,
        reactionEmoji: String = "",
        createdAt: Date = .now,
        isRead: Bool = false,
        cloudRecordName: String? = nil
    ) {
        self.id = id
        self.recipientAppleUserID = recipientAppleUserID
        self.typeRaw = type.rawValue
        self.reportID = reportID
        self.actorAppleUserID = actorAppleUserID
        self.actorDisplayName = actorDisplayName
        self.actorUsername = actorUsername
        self.title = title
        self.body = body
        self.reactionEmoji = reactionEmoji
        self.createdAt = createdAt
        self.isRead = isRead
        self.cloudRecordName = cloudRecordName
    }
}
