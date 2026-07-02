import Foundation
import SwiftData

enum FriendLinkStatus: String, Codable, CaseIterable {
    case pendingOutgoing
    case pendingIncoming
    case accepted
    case declined
}

@Model
final class FriendLink {
    var id: UUID
    var ownerAppleUserID: String
    var friendAppleUserID: String
    var friendDisplayName: String
    var friendUsername: String
    var friendAvatarEmoji: String
    var friendHomeCountry: String
    var statusRaw: String
    var cloudRecordName: String?
    var createdAt: Date
    var updatedAt: Date

    var status: FriendLinkStatus {
        get { FriendLinkStatus(rawValue: statusRaw) ?? .pendingOutgoing }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        ownerAppleUserID: String,
        friendAppleUserID: String,
        friendDisplayName: String,
        friendUsername: String,
        friendAvatarEmoji: String = "🍔",
        friendHomeCountry: String = "",
        status: FriendLinkStatus = .pendingOutgoing,
        cloudRecordName: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.ownerAppleUserID = ownerAppleUserID
        self.friendAppleUserID = friendAppleUserID
        self.friendDisplayName = friendDisplayName
        self.friendUsername = friendUsername
        self.friendAvatarEmoji = friendAvatarEmoji
        self.friendHomeCountry = friendHomeCountry
        self.statusRaw = status.rawValue
        self.cloudRecordName = cloudRecordName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
