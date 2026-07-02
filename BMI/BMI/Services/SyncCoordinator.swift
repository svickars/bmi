import Foundation
import SwiftData

@MainActor
final class SyncCoordinator: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncSummary: String?
    @Published var lastError: String?

    let cloudSync = CloudKitPublicSyncService()
    let friendLinks = FriendLinkService()

    func bootstrap(modelContext: ModelContext, currentUser: UserProfile?) async {
        do {
            try await ExchangeRateService.shared.refreshLatestRates()
        } catch {
            lastError = "Exchange rates unavailable offline. Using cached fallback rates."
        }

        guard let settings = try? modelContext.fetch(FetchDescriptor<AppSettings>()).first,
              settings.enablePublicSync,
              let currentUser else { return }

        await syncAll(modelContext: modelContext, currentUser: currentUser, settings: settings)
    }

    func syncAll(modelContext: ModelContext, currentUser: UserProfile, settings: AppSettings) async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            try await cloudSync.registerCurrentUser(currentUser)

            let pendingUploads = try modelContext.fetch(FetchDescriptor<BigMacReport>()).filter {
                $0.author?.id == currentUser.id && ($0.lastSyncedAt == nil || $0.cloudRecordName == nil)
            }

            for report in pendingUploads where report.isPublic {
                try await cloudSync.uploadReport(report, author: currentUser)
            }

            let imported = try await cloudSync.fetchPublicReports(into: modelContext, currentUser: currentUser)
            try await friendLinks.syncFriendConnections(for: currentUser, in: modelContext)

            settings.lastPublicSyncAt = .now
            lastSyncSummary = "Synced \(pendingUploads.count) uploads, imported \(imported) public reports."
            lastError = nil
            try? modelContext.save()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func uploadReport(_ report: BigMacReport, author: UserProfile, modelContext: ModelContext) async {
        guard report.isPublic else { return }
        do {
            try await cloudSync.registerCurrentUser(author)
            try await cloudSync.uploadReport(report, author: author)
            try? modelContext.save()
        } catch {
            lastError = error.localizedDescription
        }
    }
}
