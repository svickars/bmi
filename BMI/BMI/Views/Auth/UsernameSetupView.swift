import SwiftUI
import SwiftData

struct UsernameSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var syncCoordinator: SyncCoordinator

    @State private var username = ""
    @State private var isChecking = false
    @State private var isSaving = false
    @State private var validationMessage: String?
    @State private var availabilityMessage: String?
    @State private var showsErrorAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Choose a unique username so friends can find you in the global BMI index.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Username") {
                    HStack {
                        Text("@")
                            .foregroundStyle(.secondary)
                        TextField("username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    Button(isChecking ? "Checking…" : "Check Availability") {
                        Task { await checkAvailability() }
                    }
                    .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isChecking)

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if let availabilityMessage {
                        Text(availabilityMessage)
                            .font(.caption)
                            .foregroundStyle(Color.bmiGreen)
                    }
                }

                Section {
                    Text("3–20 characters. Letters, numbers, and underscores only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if isSaving {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Registering username…")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .bmiFormScreen()
            .navigationTitle("Choose Username")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Continue") {
                        Task { await saveUsername() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if authService.hasPublicProfile {
                    return
                }
                if let profile = authService.currentUserProfile(in: modelContext),
                   profile.isRegisteredPublicly {
                    authService.markPublicProfileRegistered(with: profile)
                } else if let profile = authService.currentUserProfile(in: modelContext),
                          !profile.username.hasPrefix("user_") {
                    username = profile.username
                }
            }
            .alert("Could Not Register Username", isPresented: $showsErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func checkAvailability() async {
        validationMessage = nil
        availabilityMessage = nil

        let normalized = UsernameValidator.normalize(username)
        if let error = UsernameValidator.validate(normalized) {
            validationMessage = error
            return
        }

        isChecking = true
        defer { isChecking = false }

        do {
            let available = try await syncCoordinator.cloudSync.isUsernameAvailable(
                normalized,
                excludingAppleUserID: authService.currentUserProfile(in: modelContext)?.appleUserID
            )
            availabilityMessage = available ? "@\(normalized) is available." : nil
            validationMessage = available ? nil : UsernameError.taken.errorDescription
        } catch {
            presentError(error.localizedDescription)
        }
    }

    private func saveUsername() async {
        guard authService.isAuthenticated else {
            presentError("You are not signed in. Go back and sign in with Apple again.")
            return
        }

        guard let currentUser = authService.currentUserProfile(in: modelContext) else {
            presentError("Could not load your local profile. Delete the app, reinstall, and sign in again.")
            return
        }

        guard currentUser.appleUserID != nil else {
            presentError(UsernameError.missingAppleUserID.errorDescription ?? "Missing Apple account identifier.")
            return
        }

        let normalized = UsernameValidator.normalize(username)
        if let error = UsernameValidator.validate(normalized) {
            validationMessage = error
            return
        }

        if currentUser.isRegisteredPublicly {
            authService.markPublicProfileRegistered(with: currentUser)
            return
        }

        isSaving = true
        availabilityMessage = nil
        validationMessage = nil
        defer { isSaving = false }

        currentUser.username = normalized

        do {
            try await syncCoordinator.cloudSync.registerCurrentUser(currentUser)
            try modelContext.save()
            authService.markPublicProfileRegistered(with: currentUser)
            SeedDataService.seedCommunityData(into: modelContext)
        } catch {
            presentError(error.localizedDescription)
        }
    }

    private func presentError(_ message: String) {
        validationMessage = message
        alertMessage = message
        showsErrorAlert = true
    }
}

#Preview {
    UsernameSetupView()
        .modelContainer(PreviewData.previewContainer)
        .environmentObject(AuthenticationService())
        .environmentObject(SyncCoordinator())
}
