import SwiftUI
import SwiftData

struct UsernameSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @Query(filter: #Predicate<UserProfile> { $0.isCurrentUser }) private var currentUsers: [UserProfile]

    @State private var username = ""
    @State private var isChecking = false
    @State private var isSaving = false
    @State private var validationMessage: String?
    @State private var availabilityMessage: String?

    private var currentUser: UserProfile? { currentUsers.first }

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
                            .foregroundStyle(.bmiGreen)
                    }
                }

                Section {
                    Text("3–20 characters. Letters, numbers, and underscores only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    .disabled(isSaving)
                }
            }
            .onAppear {
                if let currentUser, !currentUser.username.hasPrefix("user_") {
                    username = currentUser.username
                }
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
                excludingAppleUserID: currentUser?.appleUserID
            )
            availabilityMessage = available ? "@\(normalized) is available." : nil
            validationMessage = available ? nil : UsernameError.taken.errorDescription
        } catch {
            validationMessage = error.localizedDescription
        }
    }

    private func saveUsername() async {
        guard let currentUser else { return }

        let normalized = UsernameValidator.normalize(username)
        if let error = UsernameValidator.validate(normalized) {
            validationMessage = error
            return
        }

        isSaving = true
        defer { isSaving = false }

        currentUser.username = normalized

        do {
            try await syncCoordinator.cloudSync.registerCurrentUser(currentUser)
            try? modelContext.save()
            SeedDataService.seedCommunityData(into: modelContext)
            await syncCoordinator.bootstrap(modelContext: modelContext, currentUser: currentUser)
        } catch {
            validationMessage = error.localizedDescription
        }
    }
}

#Preview {
    UsernameSetupView()
        .modelContainer(PreviewData.previewContainer)
        .environmentObject(AuthenticationService())
        .environmentObject(SyncCoordinator())
}
