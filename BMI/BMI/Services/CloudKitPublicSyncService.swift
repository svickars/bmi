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

    func isUsernameAvailable(_ username: String, excludingAppleUserID: String?) async throws -> Bool {
        let normalized = UsernameValidator.normalize(username)
        guard UsernameValidator.validate(normalized) == nil else { return false }

        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.PublicUser.normalizedUsername, normalized)
        let query = CKQuery(recordType: CloudKitSchema.RecordType.publicUser, predicate: predicate)
        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: 5)

        for (_, result) in results {
            guard case .success(let record) = result,
                  let ownerID = record[CloudKitSchema.PublicUser.appleUserID] as? String else { continue }
            if ownerID != excludingAppleUserID {
                return false
            }
        }
        return true
    }

    func registerCurrentUser(_ profile: UserProfile) async throws {
        guard let appleUserID = profile.appleUserID else {
            throw UsernameError.missingAppleUserID
        }

        let normalized = UsernameValidator.normalize(profile.username)
        if let validationError = UsernameValidator.validate(normalized) {
            throw UsernameError.invalid(validationError)
        }

        guard try await isUsernameAvailable(normalized, excludingAppleUserID: appleUserID) else {
            throw UsernameError.taken
        }

        let recordID = CKRecord.ID(recordName: "user.\(appleUserID)")
        let record: CKRecord

        do {
            record = try await publicDatabase.record(for: recordID)
        } catch {
            record = CKRecord(recordType: CloudKitSchema.RecordType.publicUser, recordID: recordID)
        }

        record[CloudKitSchema.PublicUser.appleUserID] = appleUserID as CKRecordValue
        record[CloudKitSchema.PublicUser.displayName] = profile.displayName as CKRecordValue
        record[CloudKitSchema.PublicUser.username] = normalized as CKRecordValue
        record[CloudKitSchema.PublicUser.normalizedUsername] = normalized as CKRecordValue
        record[CloudKitSchema.PublicUser.avatarEmoji] = profile.avatarEmoji as CKRecordValue
        record[CloudKitSchema.PublicUser.avatarStyleRaw] = profile.avatarStyleRaw as CKRecordValue
        record[CloudKitSchema.PublicUser.avatarInitials] = profile.avatarInitials as CKRecordValue
        record[CloudKitSchema.PublicUser.avatarBackgroundHex] = profile.avatarBackgroundHex as CKRecordValue
        record[CloudKitSchema.PublicUser.homeCountry] = profile.homeCountry as CKRecordValue
        record[CloudKitSchema.PublicUser.updatedAt] = Date() as CKRecordValue

        let saved = try await publicDatabase.save(record)
        profile.username = normalized
        profile.isRegisteredPublicly = true
        profile.publicRecordName = saved.recordID.recordName
    }

    @discardableResult
    func uploadReport(_ report: BigMacReport, author: UserProfile) async throws -> Int {
        guard report.isPublic, let authorAppleUserID = author.appleUserID else { return 0 }

        let recordID = CKRecord.ID(recordName: "report.\(report.id.uuidString)")
        let record: CKRecord

        do {
            record = try await publicDatabase.record(for: recordID)
        } catch {
            record = CKRecord(recordType: CloudKitSchema.RecordType.publicReport, recordID: recordID)
        }

        let photos = report.photos ?? []

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
        record[CloudKitSchema.PublicReport.photoCount] = photos.count as CKRecordValue

        let saved = try await publicDatabase.save(record)
        report.cloudRecordName = saved.recordID.recordName
        report.authorAppleUserID = authorAppleUserID

        let uploadedPhotos = try await uploadPhotos(for: report)
        report.lastSyncedAt = .now
        return uploadedPhotos
    }

    func uploadPhotos(for report: BigMacReport) async throws -> Int {
        guard let photos = report.photos, !photos.isEmpty else { return 0 }

        var uploaded = 0
        for (index, photo) in photos.enumerated() {
            if photo.isSynced { continue }
            guard let payload = PhotoCompression.jpegData(from: photo.imageData) else { continue }

            let recordID = CKRecord.ID(recordName: "photo.\(report.id.uuidString).\(photo.id.uuidString)")
            let record: CKRecord
            do {
                record = try await publicDatabase.record(for: recordID)
            } catch {
                record = CKRecord(recordType: CloudKitSchema.RecordType.publicReportPhoto, recordID: recordID)
            }

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(photo.id.uuidString).jpg")
            try payload.write(to: tempURL, options: .atomic)

            record[CloudKitSchema.PublicReportPhoto.photoID] = photo.id.uuidString as CKRecordValue
            record[CloudKitSchema.PublicReportPhoto.reportID] = report.id.uuidString as CKRecordValue
            record[CloudKitSchema.PublicReportPhoto.sortIndex] = index as CKRecordValue
            record[CloudKitSchema.PublicReportPhoto.caption] = photo.caption as CKRecordValue
            record[CloudKitSchema.PublicReportPhoto.imageAsset] = CKAsset(fileURL: tempURL)
            record[CloudKitSchema.PublicReportPhoto.createdAt] = photo.createdAt as CKRecordValue

            let saved = try await publicDatabase.save(record)
            photo.cloudRecordName = saved.recordID.recordName
            photo.sortIndex = index
            photo.lastSyncedAt = .now
            uploaded += 1

            try? FileManager.default.removeItem(at: tempURL)
        }
        return uploaded
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
            try await fetchPhotos(for: report, into: context)
        }

        try? context.save()
        return imported
    }

    func fetchPhotos(for report: BigMacReport, into context: ModelContext) async throws {
        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.PublicReportPhoto.reportID, report.id.uuidString)
        let query = CKQuery(recordType: CloudKitSchema.RecordType.publicReportPhoto, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.PublicReportPhoto.sortIndex, ascending: true)]

        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: 10)

        for (_, result) in results {
            guard case .success(let record) = result,
                  let photoIDString = record[CloudKitSchema.PublicReportPhoto.photoID] as? String,
                  let photoUUID = UUID(uuidString: photoIDString),
                  let asset = record[CloudKitSchema.PublicReportPhoto.imageAsset] as? CKAsset,
                  let fileURL = asset.fileURL else { continue }

            let data = try Data(contentsOf: fileURL)
            let caption = record[CloudKitSchema.PublicReportPhoto.caption] as? String ?? ""
            let sortIndex = record[CloudKitSchema.PublicReportPhoto.sortIndex] as? Int ?? 0

            let descriptor = FetchDescriptor<ReportPhoto>(
                predicate: #Predicate { $0.id == photoUUID }
            )

            let photo: ReportPhoto
            if let existing = try? context.fetch(descriptor).first {
                photo = existing
                photo.imageData = data
            } else {
                photo = ReportPhoto(
                    id: photoUUID,
                    imageData: data,
                    caption: caption,
                    sortIndex: sortIndex,
                    cloudRecordName: record.recordID.recordName,
                    lastSyncedAt: .now
                )
                context.insert(photo)
            }

            photo.caption = caption
            photo.sortIndex = sortIndex
            photo.cloudRecordName = record.recordID.recordName
            photo.lastSyncedAt = .now
            photo.report = report

            if report.photos == nil {
                report.photos = [photo]
            } else if report.photos?.contains(where: { $0.id == photo.id }) == false {
                report.photos?.append(photo)
            }
        }

        report.photos = report.photos?.sorted { $0.sortIndex < $1.sortIndex }
    }

    func searchPublicUsers(username: String) async throws -> [PublicUserDTO] {
        let normalized = UsernameValidator.normalize(username)
        guard !normalized.isEmpty else { return [] }

        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.PublicUser.normalizedUsername, normalized)
        let query = CKQuery(recordType: CloudKitSchema.RecordType.publicUser, predicate: predicate)
        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: 20)

        return results.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return record.publicUserDTO()
        }
    }

    func fetchPublicUser(username: String) async throws -> PublicUserDTO? {
        try await searchPublicUsers(username: username).first
    }

    func fetchPublicReports(
        authorAppleUserID: String,
        into context: ModelContext,
        currentUser: UserProfile?
    ) async throws -> [BigMacReport] {
        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.PublicReport.authorAppleUserID, authorAppleUserID)
        let query = CKQuery(recordType: CloudKitSchema.RecordType.publicReport, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.PublicReport.createdAt, ascending: false)]

        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: 100)
        var reports: [BigMacReport] = []

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
            }

            apply(record: record, to: report, currentUser: currentUser, context: context)
            try await fetchPhotos(for: report, into: context)
            reports.append(report)
        }

        try? context.save()
        return reports
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

        if let authorAppleUserID = report.authorAppleUserID {
            report.author = resolveAuthor(appleUserID: authorAppleUserID, context: context, currentUser: currentUser)
        }
    }

    private func resolveAuthor(appleUserID: String, context: ModelContext, currentUser: UserProfile?) -> UserProfile? {
        if currentUser?.appleUserID == appleUserID { return currentUser }

        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.appleUserID == appleUserID }
        )
        return try? context.fetch(descriptor).first
    }
}
