import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var useDeviceLocaleCurrency: Bool
    var customNormalizationCurrencyCode: String

    init(
        id: UUID = UUID(),
        useDeviceLocaleCurrency: Bool = true,
        customNormalizationCurrencyCode: String = "USD"
    ) {
        self.id = id
        self.useDeviceLocaleCurrency = useDeviceLocaleCurrency
        self.customNormalizationCurrencyCode = customNormalizationCurrencyCode
    }

    var effectiveNormalizationCurrency: String {
        if useDeviceLocaleCurrency {
            Locale.current.currency?.identifier ?? "USD"
        } else {
            customNormalizationCurrencyCode
        }
    }
}

enum AppSettingsStore {
    static func current(in context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let settings = AppSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }
}
