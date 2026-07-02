import Foundation
import SwiftData
import CoreLocation

@Model
final class BigMacReport {
    var id: UUID
    var cost: Double
    var currencyCode: String
    var rating: Int
    var reviewText: String
    var purchasedItemsRaw: [String]
    var locationName: String
    var latitude: Double
    var longitude: Double
    var country: String
    var subRegion: String
    var locationTypeRaw: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var author: UserProfile?

    @Relationship(deleteRule: .nullify)
    var taggedFriends: [UserProfile]?

    @Relationship(deleteRule: .cascade)
    var photos: [ReportPhoto]?

    var purchasedItems: [PurchasedItem] {
        get { purchasedItemsRaw.compactMap { PurchasedItem(rawValue: $0) } }
        set { purchasedItemsRaw = newValue.map(\.rawValue) }
    }

    var locationType: LocationType {
        get { LocationType(rawValue: locationTypeRaw) ?? .other }
        set { locationTypeRaw = newValue.rawValue }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: cost)) ?? "\(currencyCode) \(cost)"
    }

    var purchasedItemsSummary: String {
        purchasedItems.map(\.displayName).joined(separator: ", ")
    }

    init(
        id: UUID = UUID(),
        cost: Double,
        currencyCode: String,
        rating: Int,
        reviewText: String = "",
        purchasedItems: [PurchasedItem] = [.bigMac],
        locationName: String,
        latitude: Double,
        longitude: Double,
        country: String,
        subRegion: String,
        locationType: LocationType = .urban,
        createdAt: Date = .now,
        author: UserProfile? = nil,
        taggedFriends: [UserProfile] = [],
        photos: [ReportPhoto] = []
    ) {
        self.id = id
        self.cost = cost
        self.currencyCode = currencyCode
        self.rating = rating
        self.reviewText = reviewText
        self.purchasedItemsRaw = purchasedItems.map(\.rawValue)
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.country = country
        self.subRegion = subRegion
        self.locationTypeRaw = locationType.rawValue
        self.createdAt = createdAt
        self.author = author
        self.taggedFriends = taggedFriends
        self.photos = photos
    }
}
