import Foundation

struct PriceAggregate: Identifiable, Hashable {
    var id: String { label }
    let label: String
    let averageCost: Double
    let averageRating: Double
    let reportCount: Int
    let currencyCode: String
}

struct StatisticsSummary {
    let totalReports: Int
    let averageRating: Double
    let countriesTracked: Int
    let cheapestCountry: PriceAggregate?
    let priciestCountry: PriceAggregate?
}

enum StatisticsService {
    static func summary(from reports: [BigMacReport]) -> StatisticsSummary {
        let bigMacReports = reports.filter { report in
            report.purchasedItems.contains { $0.isBigMacVariant }
        }

        let countryGroups = Dictionary(grouping: bigMacReports, by: \.country)
        let countryAggregates = aggregates(from: countryGroups)

        let avgRating = bigMacReports.isEmpty
            ? 0
            : Double(bigMacReports.map(\.rating).reduce(0, +)) / Double(bigMacReports.count)

        let sortedByPrice = countryAggregates.sorted { $0.averageCost < $1.averageCost }

        return StatisticsSummary(
            totalReports: bigMacReports.count,
            averageRating: avgRating,
            countriesTracked: countryAggregates.count,
            cheapestCountry: sortedByPrice.first,
            priciestCountry: sortedByPrice.last
        )
    }

    static func byCountry(from reports: [BigMacReport]) -> [PriceAggregate] {
        let bigMacReports = reports.filter { report in
            report.purchasedItems.contains { $0.isBigMacVariant }
        }
        let groups = Dictionary(grouping: bigMacReports, by: \.country)
        return aggregates(from: groups).sorted { $0.averageCost > $1.averageCost }
    }

    static func bySubRegion(from reports: [BigMacReport], country: String? = nil) -> [PriceAggregate] {
        let filtered = reports.filter { report in
            report.purchasedItems.contains { $0.isBigMacVariant }
                && (country == nil || report.country == country)
        }
        let groups = Dictionary(grouping: filtered) { "\($0.country) · \($0.subRegion)" }
        return aggregates(from: groups).sorted { $0.averageCost > $1.averageCost }
    }

    static func byLocationType(from reports: [BigMacReport]) -> [PriceAggregate] {
        let bigMacReports = reports.filter { report in
            report.purchasedItems.contains { $0.isBigMacVariant }
        }
        let groups = Dictionary(grouping: bigMacReports) { $0.locationType.displayName }
        return aggregates(from: groups).sorted { $0.averageCost > $1.averageCost }
    }

    static func ratingDistribution(from reports: [BigMacReport]) -> [(rating: Int, count: Int)] {
        (1...5).map { rating in
            (rating, reports.filter { $0.rating == rating }.count)
        }
    }

    private static func aggregates(from groups: [String: [BigMacReport]]) -> [PriceAggregate] {
        groups.map { label, items in
            let avgCost = items.map(\.cost).reduce(0, +) / Double(items.count)
            let avgRating = Double(items.map(\.rating).reduce(0, +)) / Double(items.count)
            let currency = items.first?.currencyCode ?? "USD"
            return PriceAggregate(
                label: label,
                averageCost: avgCost,
                averageRating: avgRating,
                reportCount: items.count,
                currencyCode: currency
            )
        }
    }
}
