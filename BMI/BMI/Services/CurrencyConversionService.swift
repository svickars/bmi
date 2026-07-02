import Foundation

enum CurrencyConversionService {
    private static let fallbackUSDRates: [String: Double] = [
        "USD": 1.0, "EUR": 1.08, "GBP": 1.27, "JPY": 0.0067, "CAD": 0.74,
        "AUD": 0.65, "CHF": 1.13, "CNY": 0.14, "INR": 0.012, "BRL": 0.20,
        "MXN": 0.058, "KRW": 0.00075, "SGD": 0.74, "HKD": 0.13, "SEK": 0.095,
        "NOK": 0.093, "DKK": 0.14, "PLN": 0.25, "TRY": 0.031, "AED": 0.27,
        "ZAR": 0.055, "THB": 0.028, "IDR": 0.000063, "PHP": 0.018, "NZD": 0.60,
        "ILS": 0.27, "TWD": 0.031, "MYR": 0.22
    ]

    static var supportedCurrencies: [String] {
        fallbackUSDRates.keys.sorted()
    }

    static func convertToUSD(_ amount: Double, from sourceCode: String) -> Double {
        amount * (fallbackUSDRates[sourceCode.uppercased()] ?? 1.0)
    }

    static func convertFromUSD(_ usdAmount: Double, to targetCode: String) -> Double {
        let rate = fallbackUSDRates[targetCode.uppercased()] ?? 1.0
        guard rate > 0 else { return usdAmount }
        return usdAmount / rate
    }

    static func convert(_ amount: Double, from sourceCode: String, to targetCode: String) -> Double {
        convertFromUSD(convertToUSD(amount, from: sourceCode), to: targetCode)
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
        Locale(identifier: "en_US").localizedString(forCurrencyCode: currencyCode.uppercased())
            ?? currencyCode.uppercased()
    }

    static func deviceLocaleCurrencyCode() -> String {
        Locale.current.currency?.identifier ?? "USD"
    }
}
