import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @Query private var settingsList: [AppSettings]
    @Query(filter: #Predicate<UserProfile> { $0.isCurrentUser }) private var currentUsers: [UserProfile]

    private var settings: AppSettings {
        if let first = settingsList.first {
            return first
        }
        return AppSettingsStore.current(in: modelContext)
    }

    var body: some View {
        Form {
            Section {
                Text("The global index converts every report into comparable values using live exchange rates and US CPI inflation so a meal logged today still compares fairly a year from now.")
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

            Section("Historical Comparison") {
                Toggle("Express in Today's Dollars", isOn: Binding(
                    get: { settings.useTodaysDollars },
                    set: { settings.useTodaysDollars = $0; save() }
                ))

                Text("When enabled, older reports are inflation-adjusted to today's US purchasing power before being converted into your comparison currency.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Global Public Index") {
                Toggle("Sync with CloudKit Public Database", isOn: Binding(
                    get: { settings.enablePublicSync },
                    set: { settings.enablePublicSync = $0; save() }
                ))

                if let lastSync = settings.lastPublicSyncAt {
                    LabeledContent("Last Sync") {
                        Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Sync Now") {
                    Task { await syncNow() }
                }
                .disabled(syncCoordinator.isSyncing || currentUsers.first == nil)

                if syncCoordinator.isSyncing {
                    ProgressView("Syncing public data…")
                }

                if let summary = syncCoordinator.lastSyncSummary {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let error = syncCoordinator.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Example") {
                let target = settings.effectiveNormalizationCurrency
                exampleRow(label: "¥890 JPY (today)", amount: 890, from: "JPY", to: target)
                exampleRow(label: "€5.49 EUR (6 mo ago)", amount: 5.49, from: "EUR", to: target, monthsAgo: 6)
            }

            Section("Data Sources") {
                Text("Exchange rates: Frankfurter API (live + historical). Inflation: bundled US CPI-U index. CloudKit public database stores anonymized report metadata for the global index.")
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

    private func exampleRow(label: String, amount: Double, from: String, to: String, monthsAgo: Int = 0) -> some View {
        let reportDate = Calendar.current.date(byAdding: .month, value: -monthsAgo, to: .now) ?? .now
        let usd = CurrencyConversionService.convertToUSD(amount, from: from)
        let adjustedUSD = settings.useTodaysDollars
            ? InflationService.toTodaysDollars(usdAtReportDate: usd, reportDate: reportDate)
            : usd
        let converted = CurrencyConversionService.convertFromUSD(adjustedUSD, to: to)

        return LabeledContent(label) {
            Text(CurrencyConversionService.format(converted, currencyCode: to))
                .foregroundStyle(.secondary)
        }
    }

    private func syncNow() async {
        guard let currentUser = currentUsers.first else { return }
        await syncCoordinator.syncAll(modelContext: modelContext, currentUser: currentUser, settings: settings)
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
    .environmentObject(SyncCoordinator())
}
