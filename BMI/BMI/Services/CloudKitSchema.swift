import Foundation

enum CloudKitSchema {
    static let containerIdentifier = "iCloud.com.bigmacindex.bmi"

    enum RecordType {
        static let publicUser = "PublicUser"
        static let publicReport = "PublicReport"
        static let publicReportPhoto = "PublicReportPhoto"
        static let friendConnection = "FriendConnection"
        static let userNotification = "UserNotification"
        static let reportReaction = "ReportReaction"
    }

    enum PublicUser {
        static let appleUserID = "appleUserID"
        static let displayName = "displayName"
        static let username = "username"
        static let normalizedUsername = "normalizedUsername"
        static let avatarEmoji = "avatarEmoji"
        static let avatarStyleRaw = "avatarStyleRaw"
        static let avatarInitials = "avatarInitials"
        static let avatarBackgroundHex = "avatarBackgroundHex"
        static let homeCountry = "homeCountry"
        static let updatedAt = "updatedAt"
    }

    enum PublicReport {
        static let reportID = "reportID"
        static let authorAppleUserID = "authorAppleUserID"
        static let cost = "cost"
        static let currencyCode = "currencyCode"
        static let usdAtReportDate = "usdAtReportDate"
        static let exchangeRateDate = "exchangeRateDate"
        static let rating = "rating"
        static let reviewText = "reviewText"
        static let purchasedItemsRaw = "purchasedItemsRaw"
        static let locationName = "locationName"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let country = "country"
        static let subRegion = "subRegion"
        static let locationTypeRaw = "locationTypeRaw"
        static let createdAt = "createdAt"
        static let taggedFriendAppleUserIDs = "taggedFriendAppleUserIDs"
        static let photoCount = "photoCount"
    }

    enum PublicReportPhoto {
        static let photoID = "photoID"
        static let reportID = "reportID"
        static let sortIndex = "sortIndex"
        static let caption = "caption"
        static let imageAsset = "imageAsset"
        static let createdAt = "createdAt"
    }

    enum FriendConnection {
        static let connectionID = "connectionID"
        static let fromAppleUserID = "fromAppleUserID"
        static let toAppleUserID = "toAppleUserID"
        static let fromDisplayName = "fromDisplayName"
        static let fromUsername = "fromUsername"
        static let toDisplayName = "toDisplayName"
        static let toUsername = "toUsername"
        static let status = "status"
        static let updatedAt = "updatedAt"
    }

    enum UserNotification {
        static let notificationID = "notificationID"
        static let recipientAppleUserID = "recipientAppleUserID"
        static let typeRaw = "typeRaw"
        static let reportID = "reportID"
        static let actorAppleUserID = "actorAppleUserID"
        static let actorDisplayName = "actorDisplayName"
        static let actorUsername = "actorUsername"
        static let title = "title"
        static let body = "body"
        static let reactionEmoji = "reactionEmoji"
        static let createdAt = "createdAt"
        static let isRead = "isRead"
    }

    enum ReportReaction {
        static let reactionID = "reactionID"
        static let reportID = "reportID"
        static let reactorAppleUserID = "reactorAppleUserID"
        static let reactorDisplayName = "reactorDisplayName"
        static let reactionEmoji = "reactionEmoji"
        static let createdAt = "createdAt"
    }
}

struct PublicUserDTO: Identifiable, Hashable {
    let appleUserID: String
    let displayName: String
    let username: String
    let avatarEmoji: String
    let avatarStyleRaw: String
    let avatarInitials: String
    let avatarBackgroundHex: String
    let homeCountry: String

    var id: String { appleUserID }

    var avatarStyle: AvatarStyle {
        AvatarStyle(rawValue: avatarStyleRaw) ?? .emoji
    }
}

import CloudKit

extension CKRecord {
    func publicUserDTO() -> PublicUserDTO? {
        guard recordType == CloudKitSchema.RecordType.publicUser,
              let appleUserID = self[CloudKitSchema.PublicUser.appleUserID] as? String,
              let displayName = self[CloudKitSchema.PublicUser.displayName] as? String,
              let username = self[CloudKitSchema.PublicUser.username] as? String else {
            return nil
        }

        return PublicUserDTO(
            appleUserID: appleUserID,
            displayName: displayName,
            username: username,
            avatarEmoji: self[CloudKitSchema.PublicUser.avatarEmoji] as? String ?? "🍔",
            avatarStyleRaw: self[CloudKitSchema.PublicUser.avatarStyleRaw] as? String ?? AvatarStyle.emoji.rawValue,
            avatarInitials: self[CloudKitSchema.PublicUser.avatarInitials] as? String ?? "",
            avatarBackgroundHex: self[CloudKitSchema.PublicUser.avatarBackgroundHex] as? String
                ?? AvatarAppearance.defaultBackgroundHex(for: .emoji),
            homeCountry: self[CloudKitSchema.PublicUser.homeCountry] as? String ?? ""
        )
    }
}

enum UsernameValidator {
    static func normalize(_ username: String) -> String {
        username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func validate(_ username: String) -> String? {
        let normalized = normalize(username)
        guard normalized.count >= 3 else { return "Username must be at least 3 characters." }
        guard normalized.count <= 20 else { return "Username must be 20 characters or fewer." }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        guard normalized.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return "Use letters, numbers, and underscores only."
        }
        return nil
    }
}

enum UsernameError: LocalizedError {
    case taken
    case invalid(String)
    case registrationFailed
    case missingAppleUserID

    var errorDescription: String? {
        switch self {
        case .taken:
            "That username is already taken."
        case .invalid(let message):
            message
        case .registrationFailed:
            "Could not register your username. Try again."
        case .missingAppleUserID:
            "Your Apple sign-in is missing an account identifier. Sign out and sign in again."
        }
    }
}
