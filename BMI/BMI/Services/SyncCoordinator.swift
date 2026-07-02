import Foundation
import SwiftData

@MainActor
final class SyncCoordinator: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncSummary: String?
    @Published var lastError: String?

    let cloudSync = CloudKitPublicSyncService()
    let friendLinks = FriendLinkService()
    let activityNotifications = ActivityNotificationService()
    let reactions = ReactionService()
    let notifications = CloudKitNotificationService.shared

    init() {
        SyncCoordinator.shared = self
    }

    func bootstrap(modelContext: ModelContext, currentUser: UserProfile?) async {
        await CPIService.shared.refreshIfNeeded()
        do {
            try await ExchangeRateService.shared.refreshLatestRates()
        } catch {
            lastError = "Exchange rates unavailable offline. Using cached fallback rates."
        }

        guard let currentUser, currentUser.isRegisteredPublicly else { return }

        await notifications.requestPermissionAndRegister()
        try? await notifications.configureSubscriptions(for: currentUser)

        guard let settings = try? modelContext.fetch(FetchDescriptor<AppSettings>()).first,
              settings.enablePublicSync else { return }

        await syncAll(modelContext: modelContext, currentUser: currentUser, settings: settings)
    }

    func syncAll(modelContext: ModelContext, currentUser: UserProfile, settings: AppSettings) async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            try await cloudSync.registerCurrentUser(currentUser)

            let allReports = try modelContext.fetch(FetchDescriptor<BigMacReport>())
            let pendingUploads = allReports.filter { report in
                guard report.author?.id == currentUser.id || report.authorAppleUserID == currentUser.appleUserID else {
                    return false
                }
                return report.isPublic && needsUpload(report)
            }

            var photoUploadCount = 0
            for report in pendingUploads {
                let isFirstPublicUpload = report.cloudRecordName == nil
                photoUploadCount += try await cloudSync.uploadReport(report, author: currentUser)
                if isFirstPublicUpload {
                    try await activityNotifications.fanOutReportNotifications(
                        for: report,
                        author: currentUser,
                        in: modelContext
                    )
                }
            }

            let imported = try await cloudSync.fetchPublicReports(into: modelContext, currentUser: currentUser)
            try await friendLinks.syncFriendConnections(for: currentUser, in: modelContext)
            let notificationCount = try await activityNotifications.fetchNotifications(for: currentUser, into: modelContext)
            await notifications.deliverPendingNotifications(for: currentUser, in: modelContext, settings: settings)

            settings.lastPublicSyncAt = .now
            lastSyncSummary = "Synced \(pendingUploads.count) reports, \(photoUploadCount) photos, imported \(imported) public reports, \(notificationCount) notifications."
            lastError = nil
            try? modelContext.save()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func uploadReport(_ report: BigMacReport, author: UserProfile, modelContext: ModelContext) async {
        guard report.isPublic, author.isRegisteredPublicly else { return }
        do {
            let isFirstPublicUpload = report.cloudRecordName == nil
            _ = try await cloudSync.uploadReport(report, author: author)
            if isFirstPublicUpload {
                try await activityNotifications.fanOutReportNotifications(for: report, author: author, in: modelContext)
            }
            let settings = AppSettingsStore.current(in: modelContext)
            _ = try await activityNotifications.fetchNotifications(for: author, into: modelContext)
            await notifications.deliverPendingNotifications(for: author, in: modelContext, settings: settings)
            try? modelContext.save()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func needsUpload(_ report: BigMacReport) -> Bool {
        if report.cloudRecordName == nil || report.lastSyncedAt == nil { return true }
        return report.photos?.contains(where: { !$0.isSynced }) == true
    }
}
