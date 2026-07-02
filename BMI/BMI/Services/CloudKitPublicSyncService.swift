import CloudKit
import Foundation
import SwiftData

@MainActor
final class CloudKitPublicSyncService: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published var lastError: String?

    private let container: CKContainer
    private var publicDatabase: CKDatabase { container.publicCloudDatabase }

    init(container: CKContainer = CKContainer(identifier: CloudKitSchema.containerIdentifier)) {
        self.container = container
    }

    func registerCurrentUser(_ profile: UserProfile) async throws {
        guard let appleUserID = profile.appleUserID else { return }

        let recordID = CKRecord.ID(recordName: "user.\(appleUserID)")
        let record: CKRecord

        do {
            record = try await publicDatabase.record(for: recordID)
        } catch {
            record = CKRecord(recordType: CloudKitSchema.RecordType.publicUser, recordID: recordID)
        }

        record[CloudKitSchema.PublicUser.appleUserID] = appleUserID as CKRecordValue
        record[CloudKitSchema.PublicUser.displayName] = profile.displayName as CKRecordValue
        record[CloudKitSchema.PublicUser.username] = profile.username as CKRecordValue
        record[CloudKitSchema.PublicUser.avatarEmoji] = profile.avatarEmoji as CKRecordValue
        record[CloudKitSchema.PublicUser.homeCountry] = profile.homeCountry as CKRecordValue
        record[CloudKitSchema.PublicUser.updatedAt] = Date() as CKRecordValue

        let saved = try await publicDatabase.save(record)
        profile.isRegisteredPublicly = true
        profile.publicRecordName = saved.recordID.recordName
    }

    func uploadReport(_ report: BigMacReport, author: UserProfile) async throws {
        guard report.isPublic, let authorAppleUserID = author.appleUserID else { return }

        let recordID = CKRecord.ID(recordName: "report.\(report.id.uuidString)")
        let record: CKRecord

        do {
            record = try await publicDatabase.record(for: recordID)
        } catch {
            record = CKRecord(recordType: CloudKitSchema.RecordType.publicReport, recordID: recordID)
        }

        record[CloudKitSchema.PublicReport.reportID] = report.id.uuidString as CKRecordValue
        record[CloudKitSchema.PublicReport.authorAppleUserID] = authorAppleUserID as CKRecordValue
        record[CloudKitSchema.PublicReport.cost] = report.cost as CKRecordValue
        record[CloudKitSchema.PublicReport.currencyCode] = report.currencyCode as CKRecordValue
        record[CloudKitSchema.PublicReport.usdAtReportDate] = report.usdAtReportDate as CKRecordValue
        record[CloudKitSchema.PublicReport.exchangeRateDate] = report.exchangeRateDate as CKRecordValue
        record[CloudKitSchema.PublicReport.rating] = report.rating as CKRecordValue
        record[CloudKitSchema.PublicReport.reviewText] = report.reviewText as CKRecordValue
        record[CloudKitSchema.PublicReport.purchasedItemsRaw] = report.purchasedItemsRaw as CKRecordValue
        record[CloudKitSchema.PublicReport.locationName] = report.locationName as CKRecordValue
        record[CloudKitSchema.PublicReport.latitude] = report.latitude as CKRecordValue
        record[CloudKitSchema.PublicReport.longitude] = report.longitude as CKRecordValue
        record[CloudKitSchema.PublicReport.country] = report.country as CKRecordValue
        record[CloudKitSchema.PublicReport.subRegion] = report.subRegion as CKRecordValue
        record[CloudKitSchema.PublicReport.locationTypeRaw] = report.locationTypeRaw as CKRecordValue
        record[CloudKitSchema.PublicReport.createdAt] = report.createdAt as CKRecordValue
        record[CloudKitSchema.PublicReport.taggedFriendAppleUserIDs] = report.taggedFriendAppleUserIDs as CKRecordValue

        let saved = try await publicDatabase.save(record)
        report.cloudRecordName = saved.recordID.recordName
        report.authorAppleUserID = authorAppleUserID
        report.lastSyncedAt = .now
    }

    func fetchPublicReports(into context: ModelContext, currentUser: UserProfile?) async throws -> Int {
        let query = CKQuery(recordType: CloudKitSchema.RecordType.publicReport, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.PublicReport.createdAt, ascending: false)]

        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: 200)
        var imported = 0

        for (_, result) in results {
            guard case .success(let record) = result,
                  let reportIDString = record[CloudKitSchema.PublicReport.reportID] as? String,
                  let reportUUID = UUID(uuidString: reportIDString) else { continue }

            let descriptor = FetchDescriptor<BigMacReport>(
                predicate: #Predicate { $0.id == reportUUID }
            )

            let report: BigMacReport
            if let existing = try? context.fetch(descriptor).first {
                report = existing
            } else {
                report = BigMacReport(
                    id: reportUUID,
                    cost: 0,
                    currencyCode: "USD",
                    rating: 0,
                    locationName: "",
                    latitude: 0,
                    longitude: 0,
                    country: "",
                    subRegion: ""
                )
                context.insert(report)
                imported += 1
            }

            apply(record: record, to: report, currentUser: currentUser, context: context)
        }

        try? context.save()
        return imported
    }

    func searchPublicUsers(username: String) async throws -> [PublicUserDTO] {
        let normalized = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return [] }

        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.PublicUser.username, normalized)
        let query = CKQuery(recordType: CloudKitSchema.RecordType.publicUser, predicate: predicate)
        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: 20)

        return results.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return record.publicUserDTO()
        }
    }

    private func apply(record: CKRecord, to report: BigMacReport, currentUser: UserProfile?, context: ModelContext) {
        report.cost = record[CloudKitSchema.PublicReport.cost] as? Double ?? report.cost
        report.currencyCode = record[CloudKitSchema.PublicReport.currencyCode] as? String ?? report.currencyCode
        report.usdAtReportDate = record[CloudKitSchema.PublicReport.usdAtReportDate] as? Double ?? report.usdAtReportDate
        report.exchangeRateDate = record[CloudKitSchema.PublicReport.exchangeRateDate] as? Date ?? report.exchangeRateDate
        report.rating = record[CloudKitSchema.PublicReport.rating] as? Int ?? report.rating
        report.reviewText = record[CloudKitSchema.PublicReport.reviewText] as? String ?? report.reviewText
        report.purchasedItemsRaw = record[CloudKitSchema.PublicReport.purchasedItemsRaw] as? [String] ?? report.purchasedItemsRaw
        report.locationName = record[CloudKitSchema.PublicReport.locationName] as? String ?? report.locationName
        report.latitude = record[CloudKitSchema.PublicReport.latitude] as? Double ?? report.latitude
        report.longitude = record[CloudKitSchema.PublicReport.longitude] as? Double ?? report.longitude
        report.country = record[CloudKitSchema.PublicReport.country] as? String ?? report.country
        report.subRegion = record[CloudKitSchema.PublicReport.subRegion] as? String ?? report.subRegion
        report.locationTypeRaw = record[CloudKitSchema.PublicReport.locationTypeRaw] as? String ?? report.locationTypeRaw
        report.createdAt = record[CloudKitSchema.PublicReport.createdAt] as? Date ?? report.createdAt
        report.authorAppleUserID = record[CloudKitSchema.PublicReport.authorAppleUserID] as? String
        report.taggedFriendAppleUserIDs = record[CloudKitSchema.PublicReport.taggedFriendAppleUserIDs] as? [String] ?? []
        report.cloudRecordName = record.recordID.recordName
        report.isPublic = true
        report.lastSyncedAt = .now

        if let authorAppleUserID = report.authorAppleUserID {
            report.author = resolveAuthor(appleUserID: authorAppleUserID, context: context, currentUser: currentUser)
        }
    }

    private func resolveAuthor(appleUserID: String, context: ModelContext, currentUser: UserProfile?) -> UserProfile? {
        if currentUser?.appleUserID == appleUserID { return currentUser }

        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.appleUserID == appleUserID }
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        return nil
    }
}
