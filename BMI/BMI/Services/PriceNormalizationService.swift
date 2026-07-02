import Foundation

enum PriceNormalizationService {
    /// Comparable value for index statistics: today's inflation-adjusted USD, converted to target currency.
    static func comparableAmount(
        for report: BigMacReport,
        targetCurrency: String,
        useTodaysDollars: Bool = true
    ) async -> Double {
        let usdBase = report.usdAtReportDate > 0
            ? report.usdAtReportDate
            : await fallbackUSD(for: report)

        let adjustedUSD = useTodaysDollars
            ? InflationService.toTodaysDollars(usdAtReportDate: usdBase, reportDate: report.createdAt)
            : usdBase

        if targetCurrency.uppercased() == "USD" {
            return adjustedUSD
        }

        do {
            return try await ExchangeRateService.shared.convertFromUSD(adjustedUSD, to: targetCurrency)
        } catch {
            return CurrencyConversionService.convertFromUSD(adjustedUSD, to: targetCurrency)
        }
    }

    static func comparableAmountSync(
        for report: BigMacReport,
        targetCurrency: String,
        useTodaysDollars: Bool = true
    ) -> Double {
        let usdBase = report.usdAtReportDate > 0
            ? report.usdAtReportDate
            : CurrencyConversionService.convertToUSD(report.cost, from: report.currencyCode)

        let adjustedUSD = useTodaysDollars
            ? InflationService.toTodaysDollars(usdAtReportDate: usdBase, reportDate: report.createdAt)
            : usdBase

        if targetCurrency.uppercased() == "USD" {
            return adjustedUSD
        }

        return CurrencyConversionService.convertFromUSD(adjustedUSD, to: targetCurrency)
    }

    static func captureUSDSnapshot(for cost: Double, currencyCode: String, on date: Date) async -> (usd: Double, rateDate: Date) {
        do {
            let usd = try await ExchangeRateService.shared.convertToUSD(amount: cost, currency: currencyCode, on: date)
            let (_, ratesDate) = await ExchangeRateService.shared.latestRatesSnapshot()
            return (usd, ratesDate)
        } catch {
            let usd = CurrencyConversionService.convertToUSD(cost, from: currencyCode)
            return (usd, date)
        }
    }

    static func formattedComparableValue(
        for report: BigMacReport,
        targetCurrency: String,
        useTodaysDollars: Bool = true
    ) -> String {
        let value = comparableAmountSync(for: report, targetCurrency: targetCurrency, useTodaysDollars: useTodaysDollars)
        return CurrencyConversionService.format(value, currencyCode: targetCurrency)
    }

    private static func fallbackUSD(for report: BigMacReport) async -> Double {
        do {
            return try await ExchangeRateService.shared.convertToUSD(
                amount: report.cost,
                currency: report.currencyCode,
                on: report.createdAt
            )
        } catch {
            return CurrencyConversionService.convertToUSD(report.cost, from: report.currencyCode)
        }
    }
}
