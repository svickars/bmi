import SwiftUI

struct ReportDetailView: View {
    let report: BigMacReport

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

                HStack {
                    VStack(alignment: .leading) {
                        Text("Price")
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
                .padding()
                .background(Color.bmiCream)
                .clipShape(RoundedRectangle(cornerRadius: 16))

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

                    if let author = report.author {
                        detailRow(icon: "person.fill", title: "Reporter", value: "\(author.avatarEmoji) \(author.displayName)")
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
            subRegion: "California"
        ))
    }
}
