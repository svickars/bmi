import SwiftUI
import Charts
import SwiftData

struct StatisticsView: View {
    @Query private var reports: [BigMacReport]
    @Query private var settingsList: [AppSettings]
    @State private var selectedSegment = 0
    @State private var selectedCountry: String?

    private var normalizationCurrency: String {
        settingsList.first?.effectiveNormalizationCurrency ?? CurrencyConversionService.deviceLocaleCurrencyCode()
    }

    private var useTodaysDollars: Bool {
        settingsList.first?.useTodaysDollars ?? true
    }

    private var summary: StatisticsSummary {
        StatisticsService.summary(
            from: reports,
            normalizationCurrency: normalizationCurrency,
            useTodaysDollars: useTodaysDollars
        )
    }

    private var countries: [String] {
        Array(Set(reports.map(\.country))).sorted()
    }

    private var countryData: [PriceAggregate] {
        StatisticsService.byCountry(from: reports, normalizationCurrency: normalizationCurrency, useTodaysDollars: useTodaysDollars)
    }

    private var subRegionData: [PriceAggregate] {
        StatisticsService.bySubRegion(from: reports, country: selectedCountry, normalizationCurrency: normalizationCurrency, useTodaysDollars: useTodaysDollars)
    }

    private var locationTypeData: [PriceAggregate] {
        StatisticsService.byLocationType(from: reports, normalizationCurrency: normalizationCurrency, useTodaysDollars: useTodaysDollars)
    }

    private var ratingData: [(rating: Int, count: Int)] {
        StatisticsService.ratingDistribution(from: reports)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    normalizationBanner
                    summaryCards

                    if !countryData.isEmpty {
                        highlightCards
                    }

                    Picker("View", selection: $selectedSegment) {
                        Text("Country").tag(0)
                        Text("Region").tag(1)
                        Text("Location").tag(2)
                        Text("Ratings").tag(3)
                    }
                    .pickerStyle(.segmented)

                    if selectedSegment == 1 && !countries.isEmpty {
                        countryPickerForRegions
                    }

                    chartSection
                }
                .padding()
            }
            .background(BMIScreenBackground())
            .navigationTitle("Index Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Currency Settings", systemImage: "dollarsign.circle")
                    }
                }
            }
        }
    }

    private var normalizationBanner: some View {
        BMICard {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .foregroundStyle(Color.bmiBrown)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Normalized to \(normalizationCurrency)\(useTodaysDollars ? " in today's dollars" : "")")
                        .font(BMITypography.ui(.subheadline, weight: .semibold))
                    Text("Live FX + US CPI inflation align historical reports with current purchasing power.")
                        .font(BMITypography.ui(.caption))
                        .foregroundStyle(Color.bmiMuted)
                }
                Spacer()
            }
        }
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(title: "Total Reports", value: "\(summary.totalReports)", icon: "doc.text.fill", color: .bmiRed)
            SummaryCard(title: "Avg Rating", value: String(format: "%.1f ★", summary.averageRating), icon: "star.fill", color: .bmiYellow)
            SummaryCard(title: "Countries", value: "\(summary.countriesTracked)", icon: "globe.americas.fill", color: .bmiBrown)
            SummaryCard(title: "Big Macs Tracked", value: "\(reports.filter { $0.purchasedItems.contains { $0.isBigMacVariant } }.count)", icon: "takeoutbag.and.cup.and.straw.fill", color: .bmiGreen)
        }
    }

    private var highlightCards: some View {
        HStack(spacing: 12) {
            if let cheapest = summary.cheapestCountry {
                HighlightCard(
                    title: "Cheapest",
                    location: cheapest.label,
                    value: formatCost(cheapest.averageCost, code: cheapest.currencyCode),
                    tint: .bmiGreen
                )
            }
            if let priciest = summary.priciestCountry {
                HighlightCard(
                    title: "Priciest",
                    location: priciest.label,
                    value: formatCost(priciest.averageCost, code: priciest.currencyCode),
                    tint: .bmiRed
                )
            }
        }
    }

    private var countryPickerForRegions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All Countries", selectedCountry == nil) { selectedCountry = nil }
                ForEach(countries, id: \.self) { country in
                    filterChip(country, selectedCountry == country) { selectedCountry = country }
                }
            }
        }
    }

    @ViewBuilder
    private var chartSection: some View {
        switch selectedSegment {
        case 0:
            priceChart(data: countryData, title: "Average Big Mac Price by Country")
            aggregateList(data: countryData)
        case 1:
            priceChart(data: subRegionData, title: "Average Price by Sub-Region")
            aggregateList(data: subRegionData)
        case 2:
            priceChart(data: locationTypeData, title: "Average Price by Location Type")
            aggregateList(data: locationTypeData)
        default:
            ratingChart
        }
    }

    private func priceChart(data: [PriceAggregate], title: String) -> some View {
        BMICard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(BMITypography.display(18))

                if data.isEmpty {
                    Text("No data yet")
                        .foregroundStyle(Color.bmiMuted)
                } else {
                    Chart(data.prefix(12)) { item in
                        BarMark(
                            x: .value("Price", item.averageCost),
                            y: .value("Location", item.label)
                        )
                        .foregroundStyle(Color.bmiRed.gradient)
                        .annotation(position: .trailing) {
                            Text(formatCost(item.averageCost, code: item.currencyCode))
                                .font(BMITypography.ui(.caption2))
                                .foregroundStyle(Color.bmiMuted)
                        }
                    }
                    .frame(height: min(CGFloat(data.count) * 36, 420))
                }
            }
        }
    }

    private var ratingChart: some View {
        BMICard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Rating Distribution")
                    .font(BMITypography.display(18))

                Chart(ratingData, id: \.rating) { item in
                    BarMark(
                        x: .value("Stars", "\(item.rating)★"),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(Color.bmiYellow.gradient)
                }
                .frame(height: 220)
            }
        }
    }

    private func aggregateList(data: [PriceAggregate]) -> some View {
        BMICard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Breakdown")
                    .font(BMITypography.display(18))

                ForEach(data) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label)
                                .font(BMITypography.ui(.subheadline, weight: .medium))
                            Text("\(item.reportCount) reports · \(String(format: "%.1f", item.averageRating))★ avg")
                                .font(BMITypography.ui(.caption))
                                .foregroundStyle(Color.bmiMuted)
                        }
                        Spacer()
                        Text(formatCost(item.averageCost, code: item.currencyCode))
                            .font(BMITypography.ui(.subheadline, weight: .bold))
                            .foregroundStyle(Color.bmiRed)
                    }
                    .padding(.vertical, 4)

                    if item.id != data.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func filterChip(_ title: String, _ isSelected: Bool, action: @escaping () -> Void) -> some View {
        BMIPillChip(title: title, isSelected: isSelected, action: action)
    }

    private func formatCost(_ value: Double, code: String) -> String {
        CurrencyConversionService.format(value, currencyCode: code)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        BMICard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(BMITypography.data(20, weight: .bold))
                Text(title)
                    .font(BMITypography.ui(.caption))
                    .foregroundStyle(Color.bmiMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct HighlightCard: View {
    let title: String
    let location: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(BMITypography.ui(.caption, weight: .semibold))
                .foregroundStyle(tint)
            Text(location)
                .font(BMITypography.ui(.subheadline))
                .lineLimit(2)
            Text(value)
                .font(BMITypography.data(18, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.bmiBorder, lineWidth: 1)
        }
    }
}

#Preview {
    StatisticsView()
        .modelContainer(PreviewData.previewContainer)
}
