import AuthenticationServices
import Foundation
import SwiftData

enum AuthStorage {
    private static let appleUserIDKey = "bmi.appleUserID"

    static var appleUserID: String? {
        get { UserDefaults.standard.string(forKey: appleUserIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: appleUserIDKey) }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: appleUserIDKey)
    }
}

@MainActor
final class AuthenticationService: NSObject, ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isCheckingCredential = true
    @Published private(set) var hasPublicProfile = false
    @Published var errorMessage: String?

    private var modelContext: ModelContext?
    private var activeProfile: UserProfile?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func checkExistingCredential() {
        guard let userID = AuthStorage.appleUserID else {
            isCheckingCredential = false
            isAuthenticated = false
            activeProfile = nil
            return
        }

        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { [weak self] state, _ in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .authorized:
                    self.isAuthenticated = self.ensureCurrentUserProfile(for: userID) != nil
                case .revoked, .notFound, .transferred:
                    AuthStorage.clear()
                    self.activeProfile = nil
                    self.isAuthenticated = false
                @unknown default:
                    self.activeProfile = nil
                    self.isAuthenticated = false
                }
                self.isCheckingCredential = false
            }
        }
    }

    func prepareSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Unexpected sign-in response."
                return
            }
            completeSignIn(with: credential)
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        guard let modelContext else { return }

        if let users = try? modelContext.fetch(FetchDescriptor<UserProfile>()) {
            users.filter(\.isCurrentUser).forEach { $0.isCurrentUser = false }
        }

        AuthStorage.clear()
        activeProfile = nil
        isAuthenticated = false
        hasPublicProfile = false
        try? modelContext.save()
    }

    func refreshPublicProfileStatus(from context: ModelContext? = nil) {
        guard let context = context ?? modelContext else { return }
        if currentUserProfile(in: context)?.isRegisteredPublicly == true {
            hasPublicProfile = true
        }
    }

    func markPublicProfileRegistered(with profile: UserProfile) {
        profile.isRegisteredPublicly = true
        activeProfile = profile
        hasPublicProfile = true
    }

    func currentUserProfile(in context: ModelContext? = nil) -> UserProfile? {
        guard let context = context ?? modelContext else { return nil }
        if let activeProfile, profileIsValid(activeProfile, in: context) {
            markCurrentUser(activeProfile, in: context)
            return activeProfile
        }

        if let appleUserID = AuthStorage.appleUserID,
           let profile = findProfile(withAppleUserID: appleUserID, in: context) {
            activeProfile = profile
            markCurrentUser(profile, in: context)
            return profile
        }

        if let profile = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first(where: { $0.isCurrentUser }) {
            activeProfile = profile
            return profile
        }

        if let appleUserID = AuthStorage.appleUserID {
            let profile = createLocalProfile(for: appleUserID, in: context)
            activeProfile = profile
            return profile
        }

        return nil
    }

    private func completeSignIn(with credential: ASAuthorizationAppleIDCredential) {
        guard let modelContext else {
            errorMessage = "App storage is not ready. Try again."
            return
        }

        let userID = credential.user
        AuthStorage.appleUserID = userID

        let profile = upsertProfile(from: credential, userID: userID, in: modelContext)
        profile.isCurrentUser = true
        activeProfile = profile
        try? modelContext.save()
        refreshPublicProfileStatus(from: modelContext)
        isAuthenticated = true
        errorMessage = nil
    }

    @discardableResult
    private func ensureCurrentUserProfile(for userID: String) -> UserProfile? {
        guard let modelContext else { return nil }

        if let profile = findProfile(withAppleUserID: userID, in: modelContext) {
            markCurrentUser(profile, in: modelContext)
            activeProfile = profile
            if profile.isRegisteredPublicly {
                SeedDataService.seedCommunityData(into: modelContext)
                markPublicProfileRegistered(with: profile)
            } else {
                refreshPublicProfileStatus(from: modelContext)
            }
            return profile
        }

        let profile = createLocalProfile(for: userID, in: modelContext)
        activeProfile = profile
        refreshPublicProfileStatus(from: modelContext)
        return profile
    }

    private func upsertProfile(
        from credential: ASAuthorizationAppleIDCredential,
        userID: String,
        in context: ModelContext
    ) -> UserProfile {
        if let existing = findProfile(withAppleUserID: userID, in: context) {
            if let fullName = formattedName(from: credential.fullName), !fullName.isEmpty {
                existing.displayName = fullName
            }
            if let email = credential.email {
                existing.email = email
            }
            markCurrentUser(existing, in: context)
            return existing
        }

        let displayName = formattedName(from: credential.fullName) ?? "BMI Contributor"
        let username = makeUsername(from: credential.email, userID: userID)

        if let users = try? context.fetch(FetchDescriptor<UserProfile>()) {
            users.forEach { $0.isCurrentUser = false }
        }

        let profile = UserProfile(
            displayName: displayName,
            username: username,
            avatarEmoji: "🍔",
            homeCountry: localizedRegionName(for: Locale.current.region?.identifier) ?? "Unknown",
            isCurrentUser: true,
            appleUserID: userID,
            email: credential.email
        )
        context.insert(profile)
        return profile
    }

    private func findProfile(withAppleUserID appleUserID: String, in context: ModelContext) -> UserProfile? {
        (try? context.fetch(FetchDescriptor<UserProfile>()))?
            .first { $0.appleUserID == appleUserID }
    }

    private func createLocalProfile(for appleUserID: String, in context: ModelContext) -> UserProfile {
        if let users = try? context.fetch(FetchDescriptor<UserProfile>()) {
            users.forEach { $0.isCurrentUser = false }
        }

        let profile = UserProfile(
            displayName: "BMI Contributor",
            username: "user_\(appleUserID.prefix(6))",
            avatarEmoji: "🍔",
            homeCountry: localizedRegionName(for: Locale.current.region?.identifier) ?? "Unknown",
            isCurrentUser: true,
            appleUserID: appleUserID
        )
        context.insert(profile)
        try? context.save()
        return profile
    }

    private func profileIsValid(_ profile: UserProfile, in context: ModelContext) -> Bool {
        profile.modelContext != nil && profile.appleUserID != nil
    }

    private func markCurrentUser(_ profile: UserProfile, in context: ModelContext) {
        guard !profile.isCurrentUser else { return }

        if let users = try? context.fetch(FetchDescriptor<UserProfile>()) {
            users.forEach { $0.isCurrentUser = ($0.id == profile.id) }
        }
        profile.isCurrentUser = true
        try? context.save()
    }

    private func formattedName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let formatter = PersonNameComponentsFormatter()
        let formatted = formatter.string(from: components)
        return formatted.isEmpty ? nil : formatted
    }

    private func makeUsername(from email: String?, userID: String) -> String {
        if let email, let prefix = email.split(separator: "@").first {
            return String(prefix).lowercased()
        }
        return "user_\(userID.prefix(6))"
    }

    private func localizedRegionName(for regionCode: String?) -> String? {
        guard let regionCode else { return nil }
        return Locale.current.localizedString(forRegionCode: regionCode)
    }

    #if DEBUG
    func signInAsPreviewUser(in context: ModelContext) {
        configure(modelContext: context)
        AuthStorage.appleUserID = "preview.apple.user"

        let profile: UserProfile
        if let existing = findProfile(withAppleUserID: "preview.apple.user", in: context) {
            profile = existing
            profile.isRegisteredPublicly = true
        } else {
            profile = UserProfile(
                displayName: "Alex Morgan",
                username: "alexm",
                avatarEmoji: "🍟",
                homeCountry: "United States",
                isCurrentUser: true,
                appleUserID: "preview.apple.user",
                email: "alex@example.com",
                isRegisteredPublicly: true
            )
            context.insert(profile)
        }

        if let users = try? context.fetch(FetchDescriptor<UserProfile>()) {
            users.forEach { $0.isCurrentUser = ($0.id == profile.id) }
        }
        profile.isRegisteredPublicly = true
        activeProfile = profile

        SeedDataService.seedCommunityData(into: context)
        try? context.save()
        markPublicProfileRegistered(with: profile)
        isAuthenticated = true
        isCheckingCredential = false
    }
    #endif
}
