import CloudKit
import Foundation

enum CloudKitSchema {
    static let containerIdentifier = "iCloud.com.bigmacindex.bmi"

    enum RecordType {
        static let publicUser = "PublicUser"
        static let publicReport = "PublicReport"
        static let friendConnection = "FriendConnection"
    }

    enum PublicUser {
        static let appleUserID = "appleUserID"
        static let displayName = "displayName"
        static let username = "username"
        static let avatarEmoji = "avatarEmoji"
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
}

struct PublicUserDTO: Identifiable, Hashable {
    let appleUserID: String
    let displayName: String
    let username: String
    let avatarEmoji: String
    let homeCountry: String

    var id: String { appleUserID }
}

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
            homeCountry: self[CloudKitSchema.PublicUser.homeCountry] as? String ?? ""
        )
    }
}
