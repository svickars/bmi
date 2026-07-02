import Foundation

struct FrankfurterResponse: Decodable {
    let amount: Double
    let base: String
    let date: String
    let rates: [String: Double]
}

actor ExchangeRateService {
    static let shared = ExchangeRateService()

    private let session: URLSession
    private var latestUSDRates: [String: Double] = ["USD": 1.0]
    private var latestRateDate: Date = .now
    private var historicalCache: [String: [String: Double]] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func refreshLatestRates() async throws {
        let url = URL(string: "https://api.frankfurter.app/latest?from=USD")!
        let (data, _) = try await session.data(from: url)
        let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        latestUSDRates = ["USD": 1.0].merging(decoded.rates) { _, new in new }
        latestRateDate = ISO8601DateFormatter().date(from: decoded.date + "T00:00:00Z")
            ?? DateFormatter.frankfurterDate.date(from: decoded.date)
            ?? .now
    }

    func convertToUSD(amount: Double, currency: String, on date: Date) async throws -> Double {
        let code = currency.uppercased()
        if code == "USD" { return amount }

        let rate = try await usdPerUnit(of: code, on: date)
        return amount * rate
    }

    func convertFromUSD(_ usdAmount: Double, to currency: String, usingLatest: Bool = true) async throws -> Double {
        let code = currency.uppercased()
        if code == "USD" { return usdAmount }

        if usingLatest, let unitsPerUSD = latestUSDRates[code], unitsPerUSD > 0 {
            return usdAmount * unitsPerUSD
        }

        let rate = try await usdPerUnit(of: code, on: .now)
        guard rate > 0 else { return usdAmount }
        return usdAmount / rate
    }

    func convert(_ amount: Double, from source: String, to target: String, on date: Date? = nil) async throws -> Double {
        let sourceCode = source.uppercased()
        let targetCode = target.uppercased()
        if sourceCode == targetCode { return amount }

        let usd = try await convertToUSD(amount: amount, currency: sourceCode, on: date ?? .now)
        if targetCode == "USD" { return usd }
        return try await convertFromUSD(usd, to: targetCode, usingLatest: date == nil)
    }

    func latestRatesSnapshot() -> (date: Date, rates: [String: Double]) {
        (latestRateDate, latestUSDRates)
    }

    func supportedCurrencies() -> [String] {
        Array(Set(latestUSDRates.keys).union(fallbackUSDRates.keys)).sorted()
    }

    private func usdPerUnit(of currency: String, on date: Date) async throws -> Double {
        if currency == "USD" { return 1.0 }

        let day = Calendar.current.startOfDay(for: date)
        let cacheKey = DateFormatter.frankfurterDate.string(from: day)

        if Calendar.current.isDateInToday(day),
           let unitsPerUSD = latestUSDRates[currency], unitsPerUSD > 0 {
            return 1.0 / unitsPerUSD
        }

        if let cached = historicalCache[cacheKey], let unitsPerUSD = cached[currency], unitsPerUSD > 0 {
            return 1.0 / unitsPerUSD
        }

        let url = URL(string: "https://api.frankfurter.app/\(cacheKey)?from=USD")!
        let (data, _) = try await session.data(from: url)
        let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        historicalCache[cacheKey] = decoded.rates
        latestUSDRates.merge(decoded.rates) { current, _ in current }

        if let unitsPerUSD = decoded.rates[currency], unitsPerUSD > 0 {
            return 1.0 / unitsPerUSD
        }

        if let fallback = fallbackUSDRates[currency] {
            return fallback
        }

        throw ExchangeRateError.unsupportedCurrency(currency)
    }

    /// Fallback USD value of one unit when offline or currency unsupported by Frankfurter.
    private var fallbackUSDRates: [String: Double] {
        [
            "EUR": 1.08, "GBP": 1.27, "JPY": 0.0067, "CAD": 0.74, "AUD": 0.65,
            "CHF": 1.13, "CNY": 0.14, "INR": 0.012, "BRL": 0.20, "MXN": 0.058,
            "KRW": 0.00075, "SGD": 0.74, "HKD": 0.13, "SEK": 0.095, "NOK": 0.093,
            "DKK": 0.14, "PLN": 0.25, "TRY": 0.031, "AED": 0.27, "ZAR": 0.055,
            "THB": 0.028, "IDR": 0.000063, "PHP": 0.018, "NZD": 0.60, "ILS": 0.27,
            "TWD": 0.031, "MYR": 0.22
        ]
    }
}

enum ExchangeRateError: LocalizedError {
    case unsupportedCurrency(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedCurrency(let code):
            "Exchange rate unavailable for \(code)."
        }
    }
}

private extension DateFormatter {
    static let frankfurterDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
