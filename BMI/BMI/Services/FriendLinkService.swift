import CloudKit
import Foundation
import SwiftData

@MainActor
final class FriendLinkService: ObservableObject {
    @Published private(set) var isWorking = false
    @Published var lastError: String?

    private let container: CKContainer
    private var publicDatabase: CKDatabase { container.publicCloudDatabase }

    init(container: CKContainer = CKContainer(identifier: CloudKitSchema.containerIdentifier)) {
        self.container = container
    }

    func sendFriendRequest(
        to user: PublicUserDTO,
        from currentUser: UserProfile,
        in context: ModelContext
    ) async throws {
        guard let fromAppleUserID = currentUser.appleUserID else { return }
        guard fromAppleUserID != user.appleUserID else {
            throw FriendLinkError.cannotAddSelf
        }

        isWorking = true
        defer { isWorking = false }

        let connectionID = canonicalConnectionID(from: fromAppleUserID, to: user.appleUserID)
        let recordID = CKRecord.ID(recordName: "friend.\(connectionID)")
        let record = CKRecord(recordType: CloudKitSchema.RecordType.friendConnection, recordID: recordID)

        record[CloudKitSchema.FriendConnection.connectionID] = connectionID as CKRecordValue
        record[CloudKitSchema.FriendConnection.fromAppleUserID] = fromAppleUserID as CKRecordValue
        record[CloudKitSchema.FriendConnection.toAppleUserID] = user.appleUserID as CKRecordValue
        record[CloudKitSchema.FriendConnection.fromDisplayName] = currentUser.displayName as CKRecordValue
        record[CloudKitSchema.FriendConnection.fromUsername] = currentUser.username as CKRecordValue
        record[CloudKitSchema.FriendConnection.toDisplayName] = user.displayName as CKRecordValue
        record[CloudKitSchema.FriendConnection.toUsername] = user.username as CKRecordValue
        record[CloudKitSchema.FriendConnection.status] = FriendLinkStatus.pendingOutgoing.rawValue as CKRecordValue
        record[CloudKitSchema.FriendConnection.updatedAt] = Date() as CKRecordValue

        let saved = try await publicDatabase.save(record)
        upsertLocalLink(
            ownerAppleUserID: fromAppleUserID,
            friend: user,
            status: .pendingOutgoing,
            cloudRecordName: saved.recordID.recordName,
            in: context
        )
        try? context.save()
    }

    func syncFriendConnections(for currentUser: UserProfile, in context: ModelContext) async throws {
        guard let appleUserID = currentUser.appleUserID else { return }

        isWorking = true
        defer { isWorking = false }

        let incomingPredicate = NSPredicate(format: "%K == %@", CloudKitSchema.FriendConnection.toAppleUserID, appleUserID)
        let outgoingPredicate = NSPredicate(format: "%K == %@", CloudKitSchema.FriendConnection.fromAppleUserID, appleUserID)
        let compound = NSCompoundPredicate(orPredicateWithSubpredicates: [incomingPredicate, outgoingPredicate])

        let query = CKQuery(recordType: CloudKitSchema.RecordType.friendConnection, predicate: compound)
        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: 100)

        for (_, result) in results {
            guard case .success(let record) = result else { continue }
            applyFriendRecord(record, currentUser: currentUser, context: context)
        }

        try? context.save()
    }

    func acceptRequest(_ link: FriendLink, currentUser: UserProfile, in context: ModelContext) async throws {
        guard let recordName = link.cloudRecordName else { return }

        isWorking = true
        defer { isWorking = false }

        let record = try await publicDatabase.record(for: CKRecord.ID(recordName: recordName))
        record[CloudKitSchema.FriendConnection.status] = FriendLinkStatus.accepted.rawValue as CKRecordValue
        record[CloudKitSchema.FriendConnection.updatedAt] = Date() as CKRecordValue
        try await publicDatabase.save(record)

        link.status = .accepted
        link.updatedAt = .now
        ensureAcceptedFriendProfile(for: link, context: context)
        try? context.save()
    }

    func declineRequest(_ link: FriendLink, in context: ModelContext) async throws {
        if let recordName = link.cloudRecordName {
            let record = try await publicDatabase.record(for: CKRecord.ID(recordName: recordName))
            record[CloudKitSchema.FriendConnection.status] = FriendLinkStatus.declined.rawValue as CKRecordValue
            try await publicDatabase.save(record)
        }
        context.delete(link)
        try? context.save()
    }

    func acceptedFriends(for ownerAppleUserID: String, in context: ModelContext) -> [FriendLink] {
        let descriptor = FetchDescriptor<FriendLink>(
            predicate: #Predicate {
                $0.ownerAppleUserID == ownerAppleUserID && $0.statusRaw == "accepted"
            },
            sortBy: [SortDescriptor(\.friendDisplayName)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func applyFriendRecord(_ record: CKRecord, currentUser: UserProfile, context: ModelContext) {
        guard let currentAppleUserID = currentUser.appleUserID,
              let fromAppleUserID = record[CloudKitSchema.FriendConnection.fromAppleUserID] as? String,
              let toAppleUserID = record[CloudKitSchema.FriendConnection.toAppleUserID] as? String,
              let statusRaw = record[CloudKitSchema.FriendConnection.status] as? String,
              let status = FriendLinkStatus(rawValue: statusRaw) else { return }

        if toAppleUserID == currentAppleUserID {
            let friend = PublicUserDTO(
                appleUserID: fromAppleUserID,
                displayName: record[CloudKitSchema.FriendConnection.fromDisplayName] as? String ?? "Friend",
                username: record[CloudKitSchema.FriendConnection.fromUsername] as? String ?? "friend",
                avatarEmoji: "🍔",
                avatarStyleRaw: AvatarStyle.emoji.rawValue,
                avatarInitials: "",
                avatarBackgroundHex: AvatarAppearance.defaultBackgroundHex(for: .emoji),
                homeCountry: ""
            )
            let localStatus: FriendLinkStatus = status == .pendingOutgoing ? .pendingIncoming : status
            upsertLocalLink(
                ownerAppleUserID: currentAppleUserID,
                friend: friend,
                status: localStatus,
                cloudRecordName: record.recordID.recordName,
                in: context
            )
        } else if fromAppleUserID == currentAppleUserID {
            let friend = PublicUserDTO(
                appleUserID: toAppleUserID,
                displayName: record[CloudKitSchema.FriendConnection.toDisplayName] as? String ?? "Friend",
                username: record[CloudKitSchema.FriendConnection.toUsername] as? String ?? "friend",
                avatarEmoji: "🍔",
                avatarStyleRaw: AvatarStyle.emoji.rawValue,
                avatarInitials: "",
                avatarBackgroundHex: AvatarAppearance.defaultBackgroundHex(for: .emoji),
                homeCountry: ""
            )
            upsertLocalLink(
                ownerAppleUserID: currentAppleUserID,
                friend: friend,
                status: status,
                cloudRecordName: record.recordID.recordName,
                in: context
            )
        }
    }

    private func upsertLocalLink(
        ownerAppleUserID: String,
        friend: PublicUserDTO,
        status: FriendLinkStatus,
        cloudRecordName: String?,
        in context: ModelContext
    ) {
        let friendAppleUserID = friend.appleUserID
        let descriptor = FetchDescriptor<FriendLink>(
            predicate: #Predicate {
                $0.ownerAppleUserID == ownerAppleUserID && $0.friendAppleUserID == friendAppleUserID
            }
        )

        let link = (try? context.fetch(descriptor).first) ?? FriendLink(
            ownerAppleUserID: ownerAppleUserID,
            friendAppleUserID: friend.appleUserID,
            friendDisplayName: friend.displayName,
            friendUsername: friend.username,
            friendAvatarEmoji: friend.avatarEmoji,
            friendHomeCountry: friend.homeCountry,
            status: status,
            cloudRecordName: cloudRecordName
        )

        if link.modelContext == nil {
            context.insert(link)
        }

        link.friendDisplayName = friend.displayName
        link.friendUsername = friend.username
        link.friendAvatarEmoji = friend.avatarEmoji
        link.friendHomeCountry = friend.homeCountry
        link.status = status
        link.cloudRecordName = cloudRecordName
        link.updatedAt = .now

        if status == .accepted {
            ensureAcceptedFriendProfile(for: link, context: context)
        }
    }

    private func ensureAcceptedFriendProfile(for link: FriendLink, context: ModelContext) {
        let friendAppleUserID = link.friendAppleUserID
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.appleUserID == friendAppleUserID }
        )

        if (try? context.fetch(descriptor).first) == nil {
            let profile = UserProfile(
                displayName: link.friendDisplayName,
                username: link.friendUsername,
                avatarEmoji: link.friendAvatarEmoji,
                homeCountry: link.friendHomeCountry,
                appleUserID: link.friendAppleUserID,
                isRegisteredPublicly: true
            )
            context.insert(profile)
        }
    }

    private func canonicalConnectionID(from: String, to: String) -> String {
        [from, to].sorted().joined(separator: ".")
    }
}

enum FriendLinkError: LocalizedError {
    case cannotAddSelf

    var errorDescription: String? {
        switch self {
        case .cannotAddSelf:
            "You cannot add yourself as a friend."
        }
    }
}
