import Foundation
import CoreLocation

struct ResolvedLocation: Equatable {
    var name: String
    var latitude: Double
    var longitude: Double
    var country: String
    var subRegion: String
    var currencyCode: String
}

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: ResolvedLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        errorMessage = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            errorMessage = "Location access denied. Enable it in Settings to auto-tag your McDonald's."
        default:
            isLoading = true
            manager.requestLocation()
        }
    }

    private func resolve(_ location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                errorMessage = "Could not determine address for this location."
                isLoading = false
                return
            }

            let country = placemark.country ?? "Unknown"
            let subRegion = placemark.administrativeArea ?? placemark.locality ?? "Unknown"
            let name = [
                placemark.name,
                placemark.locality,
                placemark.country
            ]
            .compactMap { $0 }
            .joined(separator: ", ")

            currentLocation = ResolvedLocation(
                name: name.isEmpty ? "Unknown Location" : name,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                country: country,
                subRegion: subRegion,
                currencyCode: CurrencyHelper.currencyCode(for: country)
            )
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            await resolve(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

enum CurrencyHelper {
    static func currencyCode(for country: String) -> String {
        let map: [String: String] = [
            "United States": "USD",
            "Canada": "CAD",
            "United Kingdom": "GBP",
            "Japan": "JPY",
            "Germany": "EUR",
            "France": "EUR",
            "Italy": "EUR",
            "Spain": "EUR",
            "Netherlands": "EUR",
            "Switzerland": "CHF",
            "Australia": "AUD",
            "New Zealand": "NZD",
            "China": "CNY",
            "India": "INR",
            "Brazil": "BRL",
            "Mexico": "MXN",
            "South Korea": "KRW",
            "Singapore": "SGD",
            "Hong Kong": "HKD",
            "Sweden": "SEK",
            "Norway": "NOK",
            "Denmark": "DKK",
            "Poland": "PLN",
            "Turkey": "TRY",
            "United Arab Emirates": "AED",
            "South Africa": "ZAR",
            "Argentina": "ARS",
            "Thailand": "THB",
            "Indonesia": "IDR",
            "Philippines": "PHP",
            "Ireland": "EUR",
            "Belgium": "EUR",
            "Austria": "EUR",
            "Portugal": "EUR",
            "Czech Republic": "CZK",
            "Hungary": "HUF",
            "Israel": "ILS",
            "Taiwan": "TWD",
            "Malaysia": "MYR"
        ]
        return map[country] ?? "USD"
    }

    static func symbol(for code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        return formatter.string(from: 0)?.replacingOccurrences(of: "0", with: "").trimmingCharacters(in: .whitespaces) ?? code
    }
}
