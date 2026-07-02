import Foundation

/// Adjusts USD amounts for US CPI inflation so historical prices can be expressed in "today's dollars."
enum InflationService {
    /// Monthly US CPI-U index values (1982-84 = 100). Extend as new data is published.
    private static let monthlyCPI: [String: Double] = [
        "2020-01": 259.1, "2020-06": 257.1, "2020-12": 260.5,
        "2021-01": 261.6, "2021-06": 271.7, "2021-12": 278.8,
        "2022-01": 281.9, "2022-06": 296.3, "2022-12": 298.8,
        "2023-01": 300.5, "2023-06": 305.1, "2023-12": 308.7,
        "2024-01": 309.7, "2024-06": 314.1, "2024-12": 317.6,
        "2025-01": 319.1, "2025-06": 321.5, "2025-12": 324.2,
        "2026-01": 326.0, "2026-06": 328.0
    ]

    static func cpiIndex(on date: Date) -> Double {
        let key = monthKey(for: date)
        if let exact = monthlyCPI[key] { return exact }

        let sortedKeys = monthlyCPI.keys.sorted()
        guard let firstKey = sortedKeys.first,
              let lastKey = sortedKeys.last,
              let firstDate = dateFromMonthKey(firstKey),
              let lastDate = dateFromMonthKey(lastKey) else {
            return 300.0
        }

        if date <= firstDate { return monthlyCPI[firstKey] ?? 300.0 }
        if date >= lastDate { return monthlyCPI[lastKey] ?? 320.0 }

        var priorKey = firstKey
        var nextKey = lastKey
        for monthKey in sortedKeys {
            guard let monthDate = dateFromMonthKey(monthKey) else { continue }
            if monthDate <= date {
                priorKey = monthKey
            } else {
                nextKey = monthKey
                break
            }
        }

        guard let priorDate = dateFromMonthKey(priorKey),
              let nextDate = dateFromMonthKey(nextKey),
              let priorCPI = monthlyCPI[priorKey],
              let nextCPI = monthlyCPI[nextKey],
              nextDate > priorDate else {
            return monthlyCPI[priorKey] ?? 300.0
        }

        let progress = date.timeIntervalSince(priorDate) / nextDate.timeIntervalSince(priorDate)
        return priorCPI + (nextCPI - priorCPI) * progress
    }

    /// Converts a USD amount observed on `reportDate` into today's purchasing-power-adjusted USD.
    static func toTodaysDollars(usdAtReportDate: Double, reportDate: Date, asOf: Date = .now) -> Double {
        guard usdAtReportDate > 0 else { return 0 }
        let reportCPI = cpiIndex(on: reportDate)
        let todayCPI = cpiIndex(on: asOf)
        guard reportCPI > 0 else { return usdAtReportDate }
        return usdAtReportDate * (todayCPI / reportCPI)
    }

    static func inflationPercent(from reportDate: Date, to: Date = .now) -> Double {
        let fromCPI = cpiIndex(on: reportDate)
        let toCPI = cpiIndex(on: to)
        guard fromCPI > 0 else { return 0 }
        return ((toCPI / fromCPI) - 1) * 100
    }

    private static func monthKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 2024, components.month ?? 1)
    }

    private static func dateFromMonthKey(_ key: String) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]) else { return nil }
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: 15))
    }
}
