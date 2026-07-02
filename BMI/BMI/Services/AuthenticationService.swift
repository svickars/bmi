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
    @Published var errorMessage: String?

    private var modelContext: ModelContext?
    private var signInContinuation: CheckedContinuation<Void, Error>?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func checkExistingCredential() {
        guard let userID = AuthStorage.appleUserID else {
            isCheckingCredential = false
            isAuthenticated = false
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
                    self.isAuthenticated = false
                @unknown default:
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
        isAuthenticated = false
        try? modelContext.save()
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

        if (try? modelContext.fetch(FetchDescriptor<UserProfile>())) != nil {
            SeedDataService.seedCommunityData(into: modelContext)
        }

        try? modelContext.save()
        isAuthenticated = true
        errorMessage = nil
    }

    @discardableResult
    private func ensureCurrentUserProfile(for userID: String) -> UserProfile? {
        guard let modelContext else { return nil }

        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.appleUserID == userID }
        )

        if let profile = try? modelContext.fetch(descriptor).first {
            if let users = try? modelContext.fetch(FetchDescriptor<UserProfile>()) {
                users.forEach { $0.isCurrentUser = ($0.id == profile.id) }
            }
            profile.isCurrentUser = true
            SeedDataService.seedCommunityData(into: modelContext)
            try? modelContext.save()
            return profile
        }

        AuthStorage.clear()
        return nil
    }

    private func upsertProfile(
        from credential: ASAuthorizationAppleIDCredential,
        userID: String,
        in context: ModelContext
    ) -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.appleUserID == userID }
        )

        if let existing = try? context.fetch(descriptor).first {
            if let fullName = formattedName(from: credential.fullName), !fullName.isEmpty {
                existing.displayName = fullName
            }
            if let email = credential.email {
                existing.email = email
            }
            if let users = try? context.fetch(FetchDescriptor<UserProfile>()) {
                users.forEach { $0.isCurrentUser = ($0.id == existing.id) }
            }
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

        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.appleUserID == "preview.apple.user" }
        )

        let profile: UserProfile
        if let existing = try? context.fetch(descriptor).first {
            profile = existing
        } else {
            profile = UserProfile(
                displayName: "Alex Morgan",
                username: "alexm",
                avatarEmoji: "🍟",
                homeCountry: "United States",
                isCurrentUser: true,
                appleUserID: "preview.apple.user",
                email: "alex@example.com"
            )
            context.insert(profile)
        }

        if let users = try? context.fetch(FetchDescriptor<UserProfile>()) {
            users.forEach { $0.isCurrentUser = ($0.id == profile.id) }
        }

        SeedDataService.seedCommunityData(into: context)
        try? context.save()
        isAuthenticated = true
        isCheckingCredential = false
    }
    #endif
}
