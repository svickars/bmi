import SwiftUI
import SwiftData

struct AddFriendView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @Query(filter: #Predicate<UserProfile> { $0.isCurrentUser }) private var currentUsers: [UserProfile]

    @State private var usernameQuery = ""
    @State private var searchResults: [PublicUserDTO] = []
    @State private var isSearching = false
    @State private var message: String?

    private var currentUser: UserProfile? { currentUsers.first }

    var body: some View {
        Form {
            Section {
                Text("Search for friends by the username they registered with Sign in with Apple.")
                    .font(BMITypography.ui(.caption))
                    .foregroundStyle(Color.bmiMuted)
            }

            Section("Find by Username") {
                HStack {
                    TextField("username", text: $usernameQuery)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Search") {
                        Task { await search() }
                    }
                    .disabled(usernameQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
                }

                if isSearching {
                    ProgressView()
                }

                ForEach(searchResults) { user in
                    NavigationLink {
                        PublicUserProfileView(username: user.username)
                    } label: {
                        HStack {
                            BMIAvatarView(user: user, size: 44)
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(BMITypography.ui(.subheadline, weight: .medium))
                                Text("@\(user.username)")
                                    .font(BMITypography.ui(.caption))
                                    .foregroundStyle(Color.bmiMuted)
                            }
                            Spacer()
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Add") {
                            Task { await sendRequest(to: user) }
                        }
                        .tint(.bmiRed)
                    }
                }
            }

            if let message {
                Section {
                    Text(message)
                        .font(BMITypography.ui(.caption))
                        .foregroundStyle(Color.bmiMuted)
                }
            }
        }
        .bmiFormScreen()
        .navigationTitle("Add Friend")
    }

    private func search() async {
        guard currentUser != nil else { return }
        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await syncCoordinator.cloudSync.searchPublicUsers(username: usernameQuery.lowercased())
            message = searchResults.isEmpty ? "No users found for @\(usernameQuery.lowercased())." : nil
        } catch {
            message = error.localizedDescription
        }
    }

    private func sendRequest(to user: PublicUserDTO) async {
        guard let currentUser else { return }

        do {
            try await syncCoordinator.friendLinks.sendFriendRequest(to: user, from: currentUser, in: modelContext)
            message = "Friend request sent to @\(user.username)."
        } catch {
            message = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        AddFriendView()
    }
    .modelContainer(PreviewData.previewContainer)
    .environmentObject(SyncCoordinator())
}
