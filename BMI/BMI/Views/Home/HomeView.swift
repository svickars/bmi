import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \BigMacReport.createdAt, order: .reverse) private var reports: [BigMacReport]
    @Query private var settingsList: [AppSettings]
    @State private var searchText = ""
    @State private var selectedCountry: String?

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerBanner

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
            .background(Color.bmiCream.opacity(0.5))
            .navigationTitle("Feed")
            .searchable(text: $searchText, prompt: "Search locations or reviews")
            .navigationDestination(for: UUID.self) { id in
                if let report = reports.first(where: { $0.id == id }) {
                    ReportDetailView(report: report)
                }
            }
        }
    }

    private var headerBanner: some View {
        let summary = StatisticsService.summary(from: reports, normalizationCurrency: normalizationCurrency)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("The Big Mac Index")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Global price intelligence from real meals")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Text("🍔")
                    .font(.system(size: 44))
            }

            HStack(spacing: 16) {
                statPill(value: "\(summary.totalReports)", label: "Reports")
                statPill(value: String(format: "%.1f", summary.averageRating), label: "Avg Rating")
                statPill(value: "\(summary.countriesTracked)", label: "Countries")
            }

            Text("Index comparisons shown in \(normalizationCurrency)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding()
        .background(BMIGradient.header)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }

    private var countryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", isSelected: selectedCountry == nil) {
                    selectedCountry = nil
                }
                ForEach(countries, id: \.self) { country in
                    filterChip(title: country, isSelected: selectedCountry == country) {
                        selectedCountry = country
                    }
                }
            }
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.bmiRed : Color(.systemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewData.previewContainer)
}
