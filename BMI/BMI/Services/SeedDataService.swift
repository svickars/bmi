import Foundation
import SwiftData
import SwiftUI

enum PreviewData {
    @MainActor
    static let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: BigMacReport.self, UserProfile.self, ReportPhoto.self, AppSettings.self, FriendLink.self,
            configurations: config
        )
        let context = container.mainContext
        _ = AppSettingsStore.current(in: context)
        SeedDataService.seedPreviewData(into: context)
        return container
    }()
}

enum SeedDataService {
    /// Community demo data (friends + global reports). Does not create the signed-in user.
    static func seedCommunityData(into context: ModelContext) {
        let existingReports = (try? context.fetch(FetchDescriptor<BigMacReport>())) ?? []
        guard existingReports.isEmpty else { return }

        let friends = ensureFriends(in: context)
        insertSampleReports(friends: friends, currentUser: nil, into: context)
        try? context.save()
    }

    /// Used by SwiftUI previews only.
    static func seedPreviewData(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        guard existing.isEmpty else { return }

        let currentUser = UserProfile(
            displayName: "Alex Morgan",
            username: "alexm",
            avatarEmoji: "🍟",
            homeCountry: "United States",
            isCurrentUser: true,
            appleUserID: "preview.apple.user",
            email: "alex@example.com"
        )
        context.insert(currentUser)

        let friends = ensureFriends(in: context)
        insertSampleReports(friends: friends, currentUser: currentUser, into: context)
        _ = AppSettingsStore.current(in: context)
        try? context.save()
    }

    private static func ensureFriends(in context: ModelContext) -> [UserProfile] {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.isCurrentUser == false && $0.appleUserID == nil }
        )
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return existing
        }

        let friends = [
            UserProfile(displayName: "Jordan Lee", username: "jlee", avatarEmoji: "🌮", homeCountry: "Canada"),
            UserProfile(displayName: "Sam Patel", username: "sam_p", avatarEmoji: "✈️", homeCountry: "United Kingdom"),
            UserProfile(displayName: "Riley Chen", username: "rileyc", avatarEmoji: "🗼", homeCountry: "France"),
            UserProfile(displayName: "Casey Brooks", username: "caseyb", avatarEmoji: "🦘", homeCountry: "Australia")
        ]
        friends.forEach { context.insert($0) }
        return friends
    }

    private static func insertSampleReports(
        friends: [UserProfile],
        currentUser: UserProfile?,
        into context: ModelContext
    ) {
        let sampleReports: [(Double, String, String, String, String, LocationType, Int, String, [PurchasedItem], [Int])] = [
            (5.69, "USD", "United States", "California", "San Francisco Downtown", .downtown, 4, "Classic SF Big Mac — solid as always.", [.bigMacMeal], [0, 1]),
            (7.49, "CAD", "Canada", "Ontario", "Toronto Union Station", .trainStation, 5, "Best airport-adjacent McDonald's I've had.", [.bigMac, .fries], [0]),
            (4.29, "GBP", "United Kingdom", "England", "London Heathrow T5", .airport, 3, "Pricey but expected at Heathrow.", [.bigMacMeal, .shake], [1, 2]),
            (890, "JPY", "Japan", "Tokyo", "Shibuya Crossing", .urban, 5, "Perfectly assembled, great sauce ratio.", [.bigMac], [2]),
            (5.49, "EUR", "Germany", "Bavaria", "Munich Autobahn A9", .highway, 4, "Quick stop, fresh and hot.", [.bigMacMeal], [0, 3]),
            (6.20, "EUR", "France", "Île-de-France", "Paris CDG Airport", .airport, 3, "Overpriced tourist trap vibes.", [.bigMac, .fries, .drink], [3]),
            (8.90, "CHF", "Switzerland", "Zürich", "Zürich HB Station", .trainStation, 4, "Swiss prices hit different.", [.doubleBigMac], [1]),
            (7.85, "AUD", "Australia", "New South Wales", "Sydney Rural Route", .rural, 5, "Surprisingly great in the middle of nowhere.", [.bigMacMeal], [4]),
            (45, "CNY", "China", "Shanghai", "Pudong Mall", .mall, 4, "Generous portion, slightly sweet bun.", [.bigMacMeal, .mcNuggets], [2, 4]),
            (249, "INR", "India", "Maharashtra", "Mumbai Western Express Highway", .highway, 3, "McChicken available — no beef Big Mac here.", [.mcChicken, .fries], [0]),
            (62, "BRL", "Brazil", "São Paulo", "Paulista Avenue", .urban, 4, "Sauce was on point today.", [.bigMacMeal], [1, 3]),
            (89, "SEK", "Sweden", "Stockholm", "Arlanda Airport", .airport, 3, "Scandinavian premium pricing.", [.bigMac], [2]),
            (5.29, "USD", "United States", "Texas", "I-35 Rest Area", .highway, 4, "Road trip essential.", [.bigMacMeal, .applePie], [0, 4]),
            (12.50, "SGD", "Singapore", "Central", "Orchard Road", .downtown, 5, "Impeccably consistent.", [.bigMac, .shake], [3]),
            (4.95, "EUR", "Spain", "Catalonia", "Barcelona Beach", .tourist, 4, "Beachside Big Mac hits different.", [.bigMacMeal], [1, 2])
        ]

        let coordinates: [(Double, Double)] = [
            (37.7879, -122.4074), (43.6452, -79.3806), (51.4700, -0.4543),
            (35.6595, 139.7004), (48.1351, 11.5820), (49.0097, 2.5479),
            (47.3786, 8.5400), (-33.8688, 151.2093), (31.2304, 121.4737),
            (19.0760, 72.8777), (-23.5505, -46.6333), (59.6519, 17.9186),
            (30.2672, -97.7431), (1.3048, 103.8318), (41.3851, 2.1734)
        ]

        for (index, sample) in sampleReports.enumerated() {
            let (cost, currency, country, subRegion, locationName, locationType, rating, review, items, friendIndices) = sample
            let coord = coordinates[index]
            let tagged = friendIndices.compactMap { friends[safe: $0] }
            let author: UserProfile? = {
                if index % 3 == 0, let currentUser { return currentUser }
                return friends[index % friends.count]
            }()

            let report = BigMacReport(
                cost: cost,
                currencyCode: currency,
                rating: rating,
                reviewText: review,
                purchasedItems: items,
                locationName: locationName,
                latitude: coord.0,
                longitude: coord.1,
                country: country,
                subRegion: subRegion,
                locationType: locationType,
                createdAt: Calendar.current.date(byAdding: .day, value: -index, to: .now) ?? .now,
                usdAtReportDate: CurrencyConversionService.convertToUSD(cost, from: currency),
                exchangeRateDate: Calendar.current.date(byAdding: .day, value: -index, to: .now) ?? .now,
                author: author,
                taggedFriends: tagged
            )
            context.insert(report)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
