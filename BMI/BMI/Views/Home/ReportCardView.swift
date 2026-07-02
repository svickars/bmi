import SwiftUI

struct ReportCardView: View {
    let report: BigMacReport

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.locationName)
                        .font(.headline)
                        .lineLimit(2)

                    Label(report.locationType.displayName, systemImage: report.locationType.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(report.formattedCost)
                        .font(.title3.bold())
                        .foregroundStyle(.bmiRed)

                    StarRatingView(rating: report.rating, size: 12)
                }
            }

            if let photo = report.photos?.first,
               let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if !report.reviewText.isEmpty {
                Text(report.reviewText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack {
                if let author = report.author {
                    Label {
                        Text(author.displayName)
                    } icon: {
                        Text(author.avatarEmoji)
                    }
                    .font(.caption)
                }

                Spacer()

                Text("\(report.country) · \(report.subRegion)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if let tagged = report.taggedFriends, !tagged.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text(tagged.map(\.displayName).joined(separator: ", "))
                        .font(.caption2)
                        .lineLimit(1)
                }
                .foregroundStyle(.bmiBrown)
            }

            Text(report.purchasedItemsSummary)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.bmiCream)
                .clipShape(Capsule())
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

#Preview {
    ReportCardView(report: BigMacReport(
        cost: 5.69,
        currencyCode: "USD",
        rating: 4,
        reviewText: "Solid Big Mac.",
        locationName: "San Francisco",
        latitude: 0,
        longitude: 0,
        country: "United States",
        subRegion: "California"
    ))
    .padding()
}
