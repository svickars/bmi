import SwiftUI
import SwiftData

struct PublicUserProfileView: View {
    let username: String

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @EnvironmentObject private var navigationRouter: AppNavigationRouter
    @Query(filter: #Predicate<UserProfile> { $0.isCurrentUser }) private var currentUsers: [UserProfile]

    @State private var publicUser: PublicUserDTO?
    @State private var reports: [BigMacReport] = []
    @State private var isLoading = true
    @State private var message: String?

    private var currentUser: UserProfile? { currentUsers.first }
    private var normalizedUsername: String { UsernameValidator.normalize(username) }

    private var isOwnProfile: Bool {
        guard let currentUser else { return false }
        return UsernameValidator.normalize(currentUser.username) == normalizedUsername
    }

    var body: some View {
        Group {
            if isOwnProfile, let currentUser {
                ProfileViewEmbedded(user: currentUser, reports: reports)
            } else if isLoading {
                ProgressView("Loading profile…")
            } else if let publicUser {
                profileContent(for: publicUser)
            } else {
                ContentUnavailableView(
                    "User Not Found",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("No public profile for @\(normalizedUsername).")
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(BMIScreenBackground())
        .navigationTitle(isOwnProfile ? "Your Profile" : "@\(normalizedUsername)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let publicUser, !isOwnProfile {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: DeepLinkRouter.userURL(username: publicUser.username)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .task(id: normalizedUsername) {
            await loadProfile()
        }
        .refreshable {
            await loadProfile()
        }
    }

    @ViewBuilder
    private func profileContent(for user: PublicUserDTO) -> some View {
        List {
            Section {
                HStack(spacing: 16) {
                    BMIAvatarView(user: user, size: 72)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(BMITypography.display(22))
                        Text("@\(user.username)")
                            .foregroundStyle(Color.bmiMuted)
                        Label(user.homeCountry, systemImage: "globe")
                            .font(BMITypography.ui(.caption))
                            .foregroundStyle(Color.bmiMuted)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Stats") {
                LabeledContent("Public Reports", value: "\(reports.count)")
                if !reports.isEmpty {
                    LabeledContent(
                        "Average Rating",
                        value: String(format: "%.1f ★", Double(reports.map(\.rating).reduce(0, +)) / Double(reports.count))
                    )
                    LabeledContent("Countries", value: "\(Set(reports.map(\.country)).count)")
                }
            }

            if currentUser != nil, !isOwnProfile {
                Section {
                    Button("Send Friend Request") {
                        Task { await sendFriendRequest(to: user) }
                    }
                }
            }

            if let message {
                Section {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Public Reports") {
                if reports.isEmpty {
                    Text("No public reports yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(reports, id: \.id) { report in
                        NavigationLink {
                            ReportDetailView(report: report)
                        } label: {
                            ReportCardView(report: report, showsAuthor: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func loadProfile() async {
        isLoading = true
        defer { isLoading = false }

        if isOwnProfile, let currentUser {
            let descriptor = FetchDescriptor<BigMacReport>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let all = (try? modelContext.fetch(descriptor)) ?? []
            reports = all.filter {
                $0.author?.id == currentUser.id || $0.authorAppleUserID == currentUser.appleUserID
            }
            return
        }

        do {
            guard let user = try await syncCoordinator.cloudSync.fetchPublicUser(username: normalizedUsername) else {
                publicUser = nil
                reports = []
                return
            }
            publicUser = user
            reports = try await syncCoordinator.cloudSync.fetchPublicReports(
                authorAppleUserID: user.appleUserID,
                into: modelContext,
                currentUser: currentUser
            )
        } catch {
            message = error.localizedDescription
        }
    }

    private func sendFriendRequest(to user: PublicUserDTO) async {
        guard let currentUser else { return }
        do {
            try await syncCoordinator.friendLinks.sendFriendRequest(to: user, from: currentUser, in: modelContext)
            message = "Friend request sent to @\(user.username)."
        } catch {
            message = error.localizedDescription
        }
    }
}

private struct ProfileViewEmbedded: View {
    let user: UserProfile
    let reports: [BigMacReport]

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    BMIAvatarView(user: user, size: 72)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(BMITypography.display(22))
                        Text("@\(user.username)")
                            .foregroundStyle(Color.bmiMuted)
                        Label(user.homeCountry, systemImage: "globe")
                            .font(BMITypography.ui(.caption))
                            .foregroundStyle(Color.bmiMuted)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Your Stats") {
                LabeledContent("Reports", value: "\(reports.count)")
            }

            Section("Your Reports") {
                ForEach(reports, id: \.id) { report in
                    NavigationLink {
                        ReportDetailView(report: report)
                    } label: {
                        ReportCardView(report: report, showsAuthor: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(BMIScreenBackground())
    }
}

#Preview {
    NavigationStack {
        PublicUserProfileView(username: "alexm")
    }
    .modelContainer(PreviewData.previewContainer)
    .environmentObject(SyncCoordinator())
    .environmentObject(AppNavigationRouter.shared)
}
