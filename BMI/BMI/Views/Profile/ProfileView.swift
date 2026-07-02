import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.displayName) private var users: [UserProfile]
    @Query(sort: \BigMacReport.createdAt, order: .reverse) private var reports: [BigMacReport]
    @Query private var settingsList: [AppSettings]

    @Query(sort: \UserNotification.createdAt, order: .reverse) private var allNotifications: [UserNotification]

    private var currentUser: UserProfile? {
        users.first { $0.isCurrentUser }
    }

    private var unreadNotificationCount: Int {
        guard let appleUserID = currentUser?.appleUserID else { return 0 }
        return allNotifications.filter { $0.recipientAppleUserID == appleUserID && !$0.isRead }.count
    }

    private var myReports: [BigMacReport] {
        guard let currentUser else { return [] }
        return reports.filter { $0.author?.id == currentUser.id || $0.authorAppleUserID == currentUser.appleUserID }
    }

    var body: some View {
        NavigationStack {
            List {
                if let user = currentUser {
                    Section {
                        HStack(spacing: 16) {
                            BMIAvatarView(user: user, size: 72)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(BMITypography.display(22))
                                Text("@\(user.username)")
                                    .foregroundStyle(Color.bmiMuted)
                                if let email = user.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Label(user.homeCountry, systemImage: "globe")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if user.isRegisteredPublicly {
                                    Label("Public profile active", systemImage: "icloud.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.bmiGreen)
                                }
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

                    Section("Social & Settings") {
                        NavigationLink {
                            AvatarEditorView(user: user)
                        } label: {
                            Label("Edit Avatar", systemImage: "face.smiling")
                        }

                        NavigationLink {
                            PublicUserProfileView(username: user.username)
                        } label: {
                            Label("Public Profile", systemImage: "person.crop.circle")
                        }

                        NavigationLink {
                            NotificationsView()
                        } label: {
                            Label("Notifications", systemImage: "bell.fill")
                        }
                        .badge(unreadNotificationCount)

                        NavigationLink {
                            FriendsManagementView()
                        } label: {
                            Label("Friends", systemImage: "person.2.fill")
                        }

                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label("Currency & Sync Settings", systemImage: "dollarsign.circle")
                        }

                        Button("Sign Out", role: .destructive) {
                            authService.signOut()
                        }
                    }

                    if syncCoordinator.isSyncing {
                        Section("Cloud Sync") {
                            ProgressView("Syncing global index…")
                        }
                    } else if let lastSync = settingsList.first?.lastPublicSyncAt {
                        Section("Cloud Sync") {
                            LabeledContent("Last Public Sync") {
                                Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("About BMI") {
                    Text("The Big Mac Index combines live exchange rates, inflation-adjusted USD, and CloudKit public data so contributors worldwide build a real global price index.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(BMIScreenBackground())
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(PreviewData.previewContainer)
        .environmentObject(AuthenticationService())
        .environmentObject(SyncCoordinator())
        .environmentObject(AppNavigationRouter.shared)
}
