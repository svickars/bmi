import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \BigMacReport.createdAt, order: .reverse) private var reports: [BigMacReport]
    @Query private var settingsList: [AppSettings]
    @State private var searchText = ""
    @State private var selectedCountry: String?

    private var useTodaysDollars: Bool {
        settingsList.first?.useTodaysDollars ?? true
    }

    private var normalizationCurrency: String {
        settingsList.first?.effectiveNormalizationCurrency ?? CurrencyConversionService.deviceLocaleCurrencyCode()
    }

    private var countries: [String] {
        Array(Set(reports.map(\.country))).sorted()
    }

    private var filteredReports: [BigMacReport] {
        reports.filter { report in
            let matchesCountry = selectedCountry == nil || report.country == selectedCountry
            let matchesSearch = searchText.isEmpty
                || report.locationName.localizedCaseInsensitiveContains(searchText)
                || report.country.localizedCaseInsensitiveContains(searchText)
                || report.reviewText.localizedCaseInsensitiveContains(searchText)
            return matchesCountry && matchesSearch
        }
    }

    private var summary: StatisticsSummary {
        StatisticsService.summary(
            from: reports,
            normalizationCurrency: normalizationCurrency,
            useTodaysDollars: useTodaysDollars
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    feedHeader

                    if !countries.isEmpty {
                        countryFilter
                    }

                    if filteredReports.isEmpty {
                        ContentUnavailableView(
                            "No Reports Yet",
                            systemImage: "takeoutbag.and.cup.and.straw.fill",
                            description: Text("Be the first to log a Big Mac price in your area.")
                        )
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(filteredReports, id: \.id) { report in
                                NavigationLink(value: report.id) {
                                    ReportCardView(report: report)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(BMIScreenBackground())
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search locations or reviews")
            .navigationDestination(for: UUID.self) { id in
                if let report = reports.first(where: { $0.id == id }) {
                    ReportDetailView(report: report)
                }
            }
        }
    }

    private var feedHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            BMISectionHeader(title: "The Index", showRule: true)

            Text("\(summary.totalReports) reports · \(String(format: "%.1f", summary.averageRating))★ · \(summary.countriesTracked) countries")
                .font(BMITypography.ui(.subheadline))
                .foregroundStyle(Color.bmiMuted)

            Text("Normalized to \(normalizationCurrency)\(useTodaysDollars ? ", today's dollars" : "")")
                .font(BMITypography.ui(.caption))
                .foregroundStyle(Color.bmiMuted)
        }
    }

    private var countryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                BMIPillChip(title: "All", isSelected: selectedCountry == nil) {
                    selectedCountry = nil
                }
                ForEach(countries, id: \.self) { country in
                    BMIPillChip(title: country, isSelected: selectedCountry == country) {
                        selectedCountry = country
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewData.previewContainer)
        .environmentObject(AppNavigationRouter.shared)
}
