import SwiftUI
import SwiftData

struct ReportDetailView: View {
    let report: BigMacReport
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @EnvironmentObject private var navigationRouter: AppNavigationRouter
    @Query private var settingsList: [AppSettings]
    @Query(filter: #Predicate<UserProfile> { $0.isCurrentUser }) private var currentUsers: [UserProfile]
    @State private var reactionRefreshToken = UUID()
    @State private var isReacting = false

    private var normalizationCurrency: String {
        settingsList.first?.effectiveNormalizationCurrency ?? CurrencyConversionService.deviceLocaleCurrencyCode()
    }

    private var useTodaysDollars: Bool {
        settingsList.first?.useTodaysDollars ?? true
    }

    private var currentUser: UserProfile? { currentUsers.first }

    private var reactions: [ReportReaction] {
        _ = reactionRefreshToken
        return syncCoordinator.reactions.reactions(for: report.id, in: modelContext)
    }

    private var reactionSummary: [(emoji: String, count: Int)] {
        syncCoordinator.reactions.reactionSummary(for: report.id, in: modelContext)
    }

    private var currentUserReaction: ReportReaction? {
        syncCoordinator.reactions.currentUserReaction(
            for: report.id,
            reactorAppleUserID: currentUser?.appleUserID,
            in: modelContext
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(report.locationName)
                        .font(.title.bold())

                    HStack {
                        Label(report.locationType.displayName, systemImage: report.locationType.icon)
                        Spacer()
                        StarRatingView(rating: report.rating)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Local Price")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(report.formattedCost)
                                .font(.largeTitle.bold())
                                .foregroundStyle(.bmiRed)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Purchased")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(report.purchasedItemsSummary)
                                .font(.subheadline.weight(.medium))
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Index Comparison")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        if report.usdAtReportDate > 0 {
                            let todaysUSD = useTodaysDollars
                                ? InflationService.toTodaysDollars(usdAtReportDate: report.usdAtReportDate, reportDate: report.createdAt)
                                : report.usdAtReportDate
                            detailLine(
                                title: "USD at report date",
                                value: CurrencyConversionService.format(report.usdAtReportDate, currencyCode: "USD")
                            )
                            if useTodaysDollars {
                                detailLine(
                                    title: "Today's dollars",
                                    value: CurrencyConversionService.format(todaysUSD, currencyCode: "USD")
                                )
                            }
                        }

                        detailLine(
                            title: "In \(normalizationCurrency)",
                            value: report.formattedComparableValue(in: normalizationCurrency, useTodaysDollars: useTodaysDollars)
                        )
                    }
                }
                .padding()
                .background(Color.bmiCream)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if report.isPublic {
                    reactionsSection
                }

                if let photos = report.photos, !photos.isEmpty {
                    TabView {
                        ForEach(photos, id: \.id) { photo in
                            if let uiImage = UIImage(data: photo.imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 240)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .frame(height: 240)
                    .tabViewStyle(.page)
                }

                if !report.reviewText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review")
                            .font(.headline)
                        Text(report.reviewText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Location Details")
                        .font(.headline)

                    detailRow(icon: "globe", title: "Country", value: report.country)
                    detailRow(icon: "map", title: "Region", value: report.subRegion)
                    detailRow(icon: "calendar", title: "Reported", value: report.createdAt.formatted(date: .abbreviated, time: .shortened))
                    detailRow(icon: "arrow.left.arrow.right", title: "FX snapshot", value: report.exchangeRateDate.formatted(date: .abbreviated, time: .omitted))

                    if report.isPublic {
                        detailRow(icon: "icloud.fill", title: "Public index", value: report.cloudRecordName == nil ? "Pending sync" : "Synced")
                    }

                    if let author = report.author {
                        Button {
                            navigationRouter.openUserProfile(username: author.username)
                        } label: {
                            detailRow(icon: "person.fill", title: "Reporter", value: "\(author.avatarEmoji) \(author.displayName)")
                        }
                        .buttonStyle(.plain)
                    }

                    if let tagged = report.taggedFriends, !tagged.isEmpty {
                        detailRow(
                            icon: "person.2.fill",
                            title: "Tagged Friends",
                            value: tagged.map { "\($0.avatarEmoji) \($0.displayName)" }.joined(separator: ", ")
                        )
                    }
                }
            }
            .padding()
        }
        .background(Color.bmiCream.opacity(0.3))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if report.isPublic {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: DeepLinkRouter.reportURL(id: report.id)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .task(id: report.id) {
            guard report.isPublic else { return }
            try? await syncCoordinator.reactions.syncReactions(for: report.id, into: modelContext)
            reactionRefreshToken = UUID()
        }
    }

    private var reactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reactions")
                .font(.headline)

            if !reactionSummary.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(reactionSummary, id: \.emoji) { item in
                        HStack(spacing: 4) {
                            Text(item.emoji)
                            Text("\(item.count)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.bmiCream)
                        .clipShape(Capsule())
                    }
                }
            }

            if currentUser != nil {
                HStack(spacing: 10) {
                    ForEach(ReactionEmoji.allCases) { reaction in
                        Button {
                            Task { await toggleReaction(reaction.rawValue) }
                        } label: {
                            Text(reaction.rawValue)
                                .font(.title2)
                                .padding(8)
                                .background(
                                    currentUserReaction?.reactionEmoji == reaction.rawValue
                                        ? Color.bmiRed.opacity(0.15)
                                        : Color.clear
                                )
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(isReacting)
                    }
                }

                if reactions.isEmpty {
                    Text("Be the first to react to this report.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Sign in to react to public reports.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.bmiCream.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func toggleReaction(_ emoji: String) async {
        guard let currentUser, !isReacting else { return }
        isReacting = true
        defer { isReacting = false }

        do {
            _ = try await syncCoordinator.reactions.toggleReaction(
                emoji: emoji,
                on: report,
                reactor: currentUser,
                in: modelContext
            )
            reactionRefreshToken = UUID()
        } catch {
            syncCoordinator.lastError = error.localizedDescription
        }
    }

    private func detailLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
        }
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.bmiBrown)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            Spacer()
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

#Preview {
    NavigationStack {
        ReportDetailView(report: BigMacReport(
            cost: 5.69,
            currencyCode: "USD",
            rating: 4,
            reviewText: "Great Big Mac!",
            locationName: "San Francisco",
            latitude: 0,
            longitude: 0,
            country: "United States",
            subRegion: "California",
            usdAtReportDate: 5.69
        ))
    }
    .modelContainer(PreviewData.previewContainer)
    .environmentObject(SyncCoordinator())
    .environmentObject(AppNavigationRouter.shared)
}
