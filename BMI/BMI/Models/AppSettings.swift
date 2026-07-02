import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var useDeviceLocaleCurrency: Bool
    var customNormalizationCurrencyCode: String
    var useTodaysDollars: Bool
    var enablePublicSync: Bool
    var lastPublicSyncAt: Date?

    init(
        id: UUID = UUID(),
        useDeviceLocaleCurrency: Bool = true,
        customNormalizationCurrencyCode: String = "USD",
        useTodaysDollars: Bool = true,
        enablePublicSync: Bool = true,
        lastPublicSyncAt: Date? = nil
    ) {
        self.id = id
        self.useDeviceLocaleCurrency = useDeviceLocaleCurrency
        self.customNormalizationCurrencyCode = customNormalizationCurrencyCode
        self.useTodaysDollars = useTodaysDollars
        self.enablePublicSync = enablePublicSync
        self.lastPublicSyncAt = lastPublicSyncAt
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
