import SwiftData
import SwiftUI

struct NotificationsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @Query(filter: #Predicate<UserProfile> { $0.isCurrentUser }) private var currentUsers: [UserProfile]
    @Query(sort: \UserNotification.createdAt, order: .reverse) private var allNotifications: [UserNotification]
    @Query private var reports: [BigMacReport]

    private var currentUser: UserProfile? { currentUsers.first }

    private var notifications: [UserNotification] {
        guard let appleUserID = currentUser?.appleUserID else { return [] }
        return allNotifications.filter { $0.recipientAppleUserID == appleUserID }
    }

    var body: some View {
        List {
            if notifications.isEmpty {
                ContentUnavailableView(
                    "No Notifications",
                    systemImage: "bell.slash",
                    description: Text("When friends post, tag you, or react to your reports, they'll show up here.")
                )
            } else {
                ForEach(notifications, id: \.id) { notification in
                    if let report = reports.first(where: { $0.id == notification.reportID }) {
                        NavigationLink {
                            ReportDetailView(report: report)
                                .onAppear {
                                    Task { await markRead(notification) }
                                }
                        } label: {
                            NotificationRow(notification: notification)
                        }
                    } else {
                        NotificationRow(notification: notification)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .bmiFormScreen()
        .navigationTitle("Notifications")
        .toolbar {
            if notifications.contains(where: { !$0.isRead }) {
                Button("Mark All Read") {
                    Task { await markAllRead() }
                }
            }
        }
        .refreshable {
            await refresh()
        }
        .task {
            await refresh()
        }
    }

    private func refresh() async {
        guard let currentUser else { return }
        _ = try? await syncCoordinator.activityNotifications.fetchNotifications(for: currentUser, into: modelContext)
    }

    private func markRead(_ notification: UserNotification) async {
        guard !notification.isRead else { return }
        try? await syncCoordinator.activityNotifications.markRead(notification)
        try? modelContext.save()
    }

    private func markAllRead() async {
        for notification in notifications where !notification.isRead {
            try? await syncCoordinator.activityNotifications.markRead(notification)
        }
        try? modelContext.save()
    }
}

private struct NotificationRow: View {
    let notification: UserNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: notification.type.icon)
                .font(.title3)
                .foregroundStyle(notification.isRead ? Color.secondary : Color.bmiRed)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(BMITypography.ui(.subheadline, weight: notification.isRead ? .regular : .semibold))
                    Spacer()
                    Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(notification.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(notification.isRead ? Color.clear : Color.bmiPaper.opacity(0.65))
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
    .modelContainer(PreviewData.previewContainer)
    .environmentObject(SyncCoordinator())
}
