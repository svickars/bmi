import SwiftUI
import SwiftData

struct FriendsManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @Query(sort: \FriendLink.updatedAt, order: .reverse) private var links: [FriendLink]
    @Query(filter: #Predicate<UserProfile> { $0.isCurrentUser }) private var currentUsers: [UserProfile]

    private var currentUser: UserProfile? { currentUsers.first }

    private var myLinks: [FriendLink] {
        guard let appleUserID = currentUser?.appleUserID else { return [] }
        return links.filter { $0.ownerAppleUserID == appleUserID }
    }

    private var incoming: [FriendLink] {
        myLinks.filter { $0.status == .pendingIncoming }
    }

    private var outgoing: [FriendLink] {
        myLinks.filter { $0.status == .pendingOutgoing }
    }

    private var accepted: [FriendLink] {
        myLinks.filter { $0.status == .accepted }
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    AddFriendView()
                } label: {
                    Label("Add Friend by Username", systemImage: "person.badge.plus")
                }
            }

            if !incoming.isEmpty {
                Section("Incoming Requests") {
                    ForEach(incoming, id: \.id) { link in
                        friendRow(link)
                        HStack {
                            Button("Accept") {
                                Task { await accept(link) }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.bmiGreen)

                            Button("Decline", role: .destructive) {
                                Task { await decline(link) }
                            }
                        }
                    }
                }
            }

            if !outgoing.isEmpty {
                Section("Pending") {
                    ForEach(outgoing, id: \.id) { link in
                        friendRow(link)
                    }
                }
            }

            Section("Friends (\(accepted.count))") {
                if accepted.isEmpty {
                    Text("Accepted friends can be tagged in your Big Mac reports.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(accepted, id: \.id) { link in
                        friendRow(link)
                    }
                }
            }
        }
        .navigationTitle("Friends")
        .refreshable {
            await refresh()
        }
    }

    private func friendRow(_ link: FriendLink) -> some View {
        NavigationLink {
            PublicUserProfileView(username: link.friendUsername)
        } label: {
            HStack(spacing: 12) {
                Text(link.friendAvatarEmoji)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(link.friendDisplayName)
                        .font(.subheadline.weight(.medium))
                    Text("@\(link.friendUsername)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func accept(_ link: FriendLink) async {
        guard let currentUser else { return }
        do {
            try await syncCoordinator.friendLinks.acceptRequest(link, currentUser: currentUser, in: modelContext)
        } catch {
            syncCoordinator.lastError = error.localizedDescription
        }
    }

    private func decline(_ link: FriendLink) async {
        do {
            try await syncCoordinator.friendLinks.declineRequest(link, in: modelContext)
        } catch {
            syncCoordinator.lastError = error.localizedDescription
        }
    }

    private func refresh() async {
        guard let currentUser,
              let settings = try? modelContext.fetch(FetchDescriptor<AppSettings>()).first else { return }
        await syncCoordinator.syncAll(modelContext: modelContext, currentUser: currentUser, settings: settings)
    }
}

#Preview {
    NavigationStack {
        FriendsManagementView()
    }
    .modelContainer(PreviewData.previewContainer)
    .environmentObject(SyncCoordinator())
}
