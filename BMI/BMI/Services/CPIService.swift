import Foundation

struct FREDObservationResponse: Decodable {
    let observations: [Observation]

    struct Observation: Decodable {
        let date: String
        let value: String
    }
}

actor CPIService {
    static let shared = CPIService()

    private var monthlyCPI: [String: Double] = InflationService.bundledMonthlyCPI
    private var lastRefresh: Date?
    private let cacheKey = "bmi.cpi.monthly.cache"
    private let cacheDateKey = "bmi.cpi.monthly.cache.date"

    init() {
        if let cached = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: Double] {
            monthlyCPI = cached
        }
        lastRefresh = UserDefaults.standard.object(forKey: cacheDateKey) as? Date
    }

    func refreshIfNeeded(force: Bool = false) async {
        if !force,
           let lastRefresh,
           Calendar.current.dateComponents([.hour], from: lastRefresh, to: .now).hour ?? 25 < 24 {
            return
        }

        guard let apiKey = Secrets.fredAPIKey, !apiKey.isEmpty else { return }

        do {
            let fetched = try await fetchFromFRED(apiKey: apiKey)
            guard !fetched.isEmpty else { return }
            monthlyCPI = fetched.merging(InflationService.bundledMonthlyCPI) { live, _ in live }
            lastRefresh = .now
            UserDefaults.standard.set(monthlyCPI, forKey: cacheKey)
            UserDefaults.standard.set(lastRefresh, forKey: cacheDateKey)
        } catch {
            // Keep cached/bundled values when live CPI is unavailable.
        }
    }

    func cpiIndex(on date: Date) -> Double {
        InflationService.interpolatedCPI(for: date, from: monthlyCPI)
    }

    var dataSourceLabel: String {
        Secrets.fredAPIKey?.isEmpty == false ? "FRED CPI-U (live, cached daily)" : "Bundled US CPI-U"
    }

    private func fetchFromFRED(apiKey: String) async throws -> [String: Double] {
        var components = URLComponents(string: "https://api.stlouisfed.org/fred/series/observations")!
        components.queryItems = [
            URLQueryItem(name: "series_id", value: "CPIAUCSL"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_type", value: "json"),
            URLQueryItem(name: "sort_order", value: "desc"),
            URLQueryItem(name: "limit", value: "120")
        ]

        guard let url = components.url else { return [:] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(FREDObservationResponse.self, from: data)

        var result: [String: Double] = [:]
        for observation in decoded.observations {
            guard observation.value != ".", let value = Double(observation.value) else { continue }
            let monthKey = String(observation.date.prefix(7))
            result[monthKey] = value
        }
        return result
    }
}

enum Secrets {
    static var fredAPIKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "FRED_API_KEY") as? String
    }
}
