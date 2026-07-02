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
    let normalizationCurrency: String
}

enum StatisticsService {
    static func summary(from reports: [BigMacReport], normalizationCurrency: String) -> StatisticsSummary {
        let bigMacReports = bigMacReports(from: reports)
        let countryGroups = Dictionary(grouping: bigMacReports, by: \.country)
        let countryAggregates = aggregates(from: countryGroups, normalizationCurrency: normalizationCurrency)

        let avgRating = bigMacReports.isEmpty
            ? 0
            : Double(bigMacReports.map(\.rating).reduce(0, +)) / Double(bigMacReports.count)

        let sortedByPrice = countryAggregates.sorted { $0.averageCost < $1.averageCost }

        return StatisticsSummary(
            totalReports: bigMacReports.count,
            averageRating: avgRating,
            countriesTracked: countryAggregates.count,
            cheapestCountry: sortedByPrice.first,
            priciestCountry: sortedByPrice.last,
            normalizationCurrency: normalizationCurrency
        )
    }

    static func byCountry(from reports: [BigMacReport], normalizationCurrency: String) -> [PriceAggregate] {
        let groups = Dictionary(grouping: bigMacReports(from: reports), by: \.country)
        return aggregates(from: groups, normalizationCurrency: normalizationCurrency)
            .sorted { $0.averageCost > $1.averageCost }
    }

    static func bySubRegion(
        from reports: [BigMacReport],
        country: String? = nil,
        normalizationCurrency: String
    ) -> [PriceAggregate] {
        let filtered = bigMacReports(from: reports).filter { country == nil || $0.country == country }
        let groups = Dictionary(grouping: filtered) { "\($0.country) · \($0.subRegion)" }
        return aggregates(from: groups, normalizationCurrency: normalizationCurrency)
            .sorted { $0.averageCost > $1.averageCost }
    }

    static func byLocationType(from reports: [BigMacReport], normalizationCurrency: String) -> [PriceAggregate] {
        let groups = Dictionary(grouping: bigMacReports(from: reports)) { $0.locationType.displayName }
        return aggregates(from: groups, normalizationCurrency: normalizationCurrency)
            .sorted { $0.averageCost > $1.averageCost }
    }

    static func ratingDistribution(from reports: [BigMacReport]) -> [(rating: Int, count: Int)] {
        (1...5).map { rating in
            (rating, reports.filter { $0.rating == rating }.count)
        }
    }

    private static func bigMacReports(from reports: [BigMacReport]) -> [BigMacReport] {
        reports.filter { report in
            report.purchasedItems.contains { $0.isBigMacVariant }
        }
    }

    private static func aggregates(
        from groups: [String: [BigMacReport]],
        normalizationCurrency: String
    ) -> [PriceAggregate] {
        groups.map { label, items in
            let normalizedCosts = items.map {
                CurrencyConversionService.convert($0.cost, from: $0.currencyCode, to: normalizationCurrency)
            }
            let avgCost = normalizedCosts.reduce(0, +) / Double(items.count)
            let avgRating = Double(items.map(\.rating).reduce(0, +)) / Double(items.count)
            return PriceAggregate(
                label: label,
                averageCost: avgCost,
                averageRating: avgRating,
                reportCount: items.count,
                currencyCode: normalizationCurrency
            )
        }
    }
}
