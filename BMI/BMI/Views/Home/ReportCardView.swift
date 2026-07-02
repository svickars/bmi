import SwiftUI

struct ReportCardView: View {
    let report: BigMacReport
    var showsAuthor: Bool = true

    @EnvironmentObject private var navigationRouter: AppNavigationRouter

    var body: some View {
        BMICard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        if showsAuthor, let author = report.author {
                            Button {
                                navigationRouter.openUserProfile(username: author.username)
                            } label: {
                                HStack(spacing: 8) {
                                    BMIAvatarView(user: author, size: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(author.displayName)
                                            .font(BMITypography.ui(.subheadline, weight: .semibold))
                                            .foregroundStyle(Color.bmiInk)
                                        Text(report.locationName)
                                            .font(BMITypography.ui(.caption))
                                            .foregroundStyle(Color.bmiMuted)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(report.locationName)
                                .font(BMITypography.ui(.headline))
                                .foregroundStyle(Color.bmiInk)
                                .lineLimit(2)
                        }

                        Label(report.locationType.displayName, systemImage: report.locationType.icon)
                            .font(BMITypography.ui(.caption))
                            .foregroundStyle(Color.bmiMuted)
                    }

                    Spacer(minLength: 8)

                    BMIPriceBadge(text: report.formattedCost, diameter: 58)
                }
                .padding(16)

                if let photo = report.photos?.first,
                   let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .bmiBiteClip()
                        .padding(.horizontal, 16)
                }

                VStack(alignment: .leading, spacing: 10) {
                    if !report.reviewText.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes:")
                                .font(BMITypography.ui(.subheadline, weight: .semibold))
                            Text(report.reviewText)
                                .font(BMITypography.ui(.subheadline))
                                .foregroundStyle(Color.bmiMuted)
                                .lineLimit(3)
                        }
                    }

                    HStack {
                        StarRatingView(rating: report.rating, size: 12)
                        Spacer()
                        Text("\(report.country) · \(report.subRegion)")
                            .font(BMITypography.ui(.caption2))
                            .foregroundStyle(Color.bmiMuted)
                    }

                    if let tagged = report.taggedFriends, !tagged.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text(tagged.map(\.displayName).joined(separator: ", "))
                                .font(BMITypography.ui(.caption2))
                                .lineLimit(1)
                        }
                        .foregroundStyle(Color.bmiBrown)
                    }

                    Text(report.purchasedItemsSummary)
                        .font(BMITypography.ui(.caption))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.bmiCream)
                        .clipShape(Capsule())
                }
                .padding(16)
            }
        }
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
    .background(BMIScreenBackground())
    .environmentObject(AppNavigationRouter.shared)
}
