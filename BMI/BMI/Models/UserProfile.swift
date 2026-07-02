import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var displayName: String
    var username: String
    var avatarEmoji: String
    var avatarStyleRaw: String
    var avatarInitials: String
    var avatarBackgroundHex: String
    var homeCountry: String
    var createdAt: Date
    var isCurrentUser: Bool
    var appleUserID: String?
    var email: String?
    var isRegisteredPublicly: Bool
    var publicRecordName: String?

    @Relationship(deleteRule: .nullify, inverse: \BigMacReport.author)
    var reports: [BigMacReport]?

    @Relationship(deleteRule: .nullify, inverse: \BigMacReport.taggedFriends)
    var taggedInReports: [BigMacReport]?

    init(
        id: UUID = UUID(),
        displayName: String,
        username: String,
        avatarEmoji: String = "🍔",
        avatarStyleRaw: String = AvatarStyle.emoji.rawValue,
        avatarInitials: String = "",
        avatarBackgroundHex: String = AvatarAppearance.defaultBackgroundHex(for: .emoji),
        homeCountry: String = "United States",
        createdAt: Date = .now,
        isCurrentUser: Bool = false,
        appleUserID: String? = nil,
        email: String? = nil,
        isRegisteredPublicly: Bool = false,
        publicRecordName: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.avatarEmoji = avatarEmoji
        self.avatarStyleRaw = avatarStyleRaw
        self.avatarInitials = avatarInitials
        self.avatarBackgroundHex = avatarBackgroundHex
        self.homeCountry = homeCountry
        self.createdAt = createdAt
        self.isCurrentUser = isCurrentUser
        self.appleUserID = appleUserID
        self.email = email
        self.isRegisteredPublicly = isRegisteredPublicly
        self.publicRecordName = publicRecordName
    }
}
