import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]

    private var settings: AppSettings {
        if let first = settingsList.first {
            return first
        }
        return AppSettingsStore.current(in: modelContext)
    }

    var body: some View {
        Form {
            Section {
                Text("Compare prices across countries by converting all reports into one currency. Original prices are always preserved on each report.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Normalization Currency") {
                Toggle("Use Device Locale", isOn: Binding(
                    get: { settings.useDeviceLocaleCurrency },
                    set: { settings.useDeviceLocaleCurrency = $0; save() }
                ))

                if settings.useDeviceLocaleCurrency {
                    LabeledContent("Current Locale Currency") {
                        Text(localeCurrencyLabel)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Picker("Compare In", selection: Binding(
                        get: { settings.customNormalizationCurrencyCode },
                        set: { settings.customNormalizationCurrencyCode = $0; save() }
                    )) {
                        ForEach(CurrencyConversionService.supportedCurrencies, id: \.self) { code in
                            Text("\(code) — \(CurrencyConversionService.displayName(for: code))")
                                .tag(code)
                        }
                    }
                }
            }

            Section("Example") {
                let target = settings.effectiveNormalizationCurrency
                LabeledContent("¥890 JPY", value: CurrencyConversionService.format(
                    CurrencyConversionService.convert(890, from: "JPY", to: target),
                    currencyCode: target
                ))
                LabeledContent("€5.49 EUR", value: CurrencyConversionService.format(
                    CurrencyConversionService.convert(5.49, from: "EUR", to: target),
                    currencyCode: target
                ))
                LabeledContent("£4.29 GBP", value: CurrencyConversionService.format(
                    CurrencyConversionService.convert(4.29, from: "GBP", to: target),
                    currencyCode: target
                ))
            }

            Section("Exchange Rates") {
                Text("Rates are bundled for offline use and approximate market values. Live rate updates can be added in a future release.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }

    private var localeCurrencyLabel: String {
        let code = CurrencyConversionService.deviceLocaleCurrencyCode()
        return "\(code) — \(CurrencyConversionService.displayName(for: code))"
    }

    private func save() {
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(PreviewData.previewContainer)
}
