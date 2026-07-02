import SwiftUI
import SwiftData

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @Query(filter: #Predicate<UserProfile> { $0.isCurrentUser }) private var currentUsers: [UserProfile]

    @State private var confirmText = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private var currentUser: UserProfile? { currentUsers.first }
    private var canDelete: Bool { confirmText.uppercased() == "DELETE" }

    var body: some View {
        Form {
            Section {
                Text("Deleting your account permanently removes your public BMI profile, reports, photos, friend links, reactions, and notifications from CloudKit and clears local app data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("What happens next") {
                Label("Public reports and profile are removed", systemImage: "icloud.slash")
                Label("You are signed out on this device", systemImage: "rectangle.portrait.and.arrow.right")
                Label("Revoke Sign in with Apple anytime in iOS Settings", systemImage: "gear")
            }

            Section("Confirm") {
                TextField("Type DELETE to confirm", text: $confirmText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }

            Section {
                Button("Delete Account Permanently", role: .destructive) {
                    Task { await deleteAccount() }
                }
                .disabled(!canDelete || isDeleting || currentUser == nil)
            }

            if isDeleting {
                Section {
                    ProgressView("Deleting account…")
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteAccount() async {
        guard let currentUser else { return }
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        do {
            try await syncCoordinator.accountDeletion.deleteAccount(for: currentUser, in: modelContext)
            authService.signOut()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        DeleteAccountView()
    }
    .modelContainer(PreviewData.previewContainer)
    .environmentObject(AuthenticationService())
    .environmentObject(SyncCoordinator())
}
