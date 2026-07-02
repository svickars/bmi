import Foundation

enum CurrencyConversionService {
    /// USD value of one unit of each currency (e.g. 1 EUR ≈ 1.08 USD).
    private static let usdPerUnit: [String: Double] = [
        "USD": 1.0,
        "EUR": 1.08,
        "GBP": 1.27,
        "JPY": 0.0067,
        "CAD": 0.74,
        "AUD": 0.65,
        "CHF": 1.13,
        "CNY": 0.14,
        "INR": 0.012,
        "BRL": 0.20,
        "MXN": 0.058,
        "KRW": 0.00075,
        "SGD": 0.74,
        "HKD": 0.13,
        "SEK": 0.095,
        "NOK": 0.093,
        "DKK": 0.14,
        "PLN": 0.25,
        "TRY": 0.031,
        "AED": 0.27,
        "ZAR": 0.055,
        "ARS": 0.0011,
        "THB": 0.028,
        "IDR": 0.000063,
        "PHP": 0.018,
        "CZK": 0.043,
        "HUF": 0.0027,
        "ILS": 0.27,
        "TWD": 0.031,
        "MYR": 0.22,
        "NZD": 0.60
    ]

    static let supportedCurrencies: [String] = {
        usdPerUnit.keys.sorted()
    }()

    static func convert(_ amount: Double, from sourceCode: String, to targetCode: String) -> Double {
        let source = sourceCode.uppercased()
        let target = targetCode.uppercased()
        guard source != target else { return amount }

        let usdAmount = amount * (usdPerUnit[source] ?? 1.0)
        let targetRate = usdPerUnit[target] ?? 1.0
        guard targetRate > 0 else { return usdAmount }
        return usdAmount / targetRate
    }

    static func format(_ amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode.uppercased()
        let zeroDecimal = ["JPY", "KRW", "IDR", "VND"]
        formatter.maximumFractionDigits = zeroDecimal.contains(currencyCode.uppercased()) ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencyCode.uppercased()) \(amount)"
    }

    static func displayName(for currencyCode: String) -> String {
        let locale = Locale(identifier: "en_US")
        return locale.localizedString(forCurrencyCode: currencyCode.uppercased()) ?? currencyCode.uppercased()
    }

    static func deviceLocaleCurrencyCode() -> String {
        Locale.current.currency?.identifier ?? "USD"
    }
}
