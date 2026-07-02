import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @Query(sort: \UserProfile.displayName) private var users: [UserProfile]
    @Query(sort: \BigMacReport.createdAt, order: .reverse) private var reports: [BigMacReport]

    private var currentUser: UserProfile? {
        users.first { $0.isCurrentUser }
    }

    private var myReports: [BigMacReport] {
        guard let currentUser else { return [] }
        return reports.filter { $0.author?.id == currentUser.id }
    }

    private var friends: [UserProfile] {
        users.filter { !$0.isCurrentUser && $0.appleUserID == nil }
    }

    var body: some View {
        NavigationStack {
            List {
                if let user = currentUser {
                    Section {
                        HStack(spacing: 16) {
                            Text(user.avatarEmoji)
                                .font(.system(size: 52))
                                .frame(width: 72, height: 72)
                                .background(Color.bmiCream)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.title2.bold())
                                Text("@\(user.username)")
                                    .foregroundStyle(.secondary)
                                if let email = user.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Label(user.homeCountry, systemImage: "globe")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Section("Your Stats") {
                        LabeledContent("Reports Submitted", value: "\(myReports.count)")
                        if !myReports.isEmpty {
                            LabeledContent(
                                "Average Rating Given",
                                value: String(format: "%.1f ★", Double(myReports.map(\.rating).reduce(0, +)) / Double(myReports.count))
                            )
                            LabeledContent(
                                "Countries Visited",
                                value: "\(Set(myReports.map(\.country)).count)"
                            )
                        }
                    }

                    Section("Account") {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label("Currency & Settings", systemImage: "dollarsign.circle")
                        }

                        Button("Sign Out", role: .destructive) {
                            authService.signOut()
                        }
                    }
                }

                Section("Community Friends (\(friends.count))") {
                    ForEach(friends, id: \.id) { friend in
                        HStack(spacing: 12) {
                            Text(friend.avatarEmoji)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text(friend.displayName)
                                    .font(.subheadline.weight(.medium))
                                Text("@\(friend.username) · \(friend.homeCountry)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(reports.filter { $0.author?.id == friend.id }.count)")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.bmiCream)
                                .clipShape(Capsule())
                        }
                    }
                }

                Section("About BMI") {
                    Text("The Big Mac Index (BMI) tracks real-world Big Mac prices and quality ratings from contributors worldwide — inspired by The Economist's purchasing power benchmark.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(PreviewData.previewContainer)
        .environmentObject(AuthenticationService())
}
