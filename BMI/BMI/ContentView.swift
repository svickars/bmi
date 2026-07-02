import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = AuthenticationService()
    @StateObject private var syncCoordinator = SyncCoordinator()
    @Query(filter: #Predicate<UserProfile> { $0.isCurrentUser }) private var currentUsers: [UserProfile]

    private var currentUser: UserProfile? { currentUsers.first }

    var body: some View {
        Group {
            if authService.isCheckingCredential {
                LaunchLoadingView()
            } else if authService.isAuthenticated {
                if currentUser?.isRegisteredPublicly == true {
                    MainTabView()
                } else {
                    UsernameSetupView()
                }
            } else {
                SignInView()
            }
        }
        .environmentObject(authService)
        .environmentObject(syncCoordinator)
        .onAppear {
            authService.configure(modelContext: modelContext)
            authService.checkExistingCredential()
            _ = AppSettingsStore.current(in: modelContext)

            AppNotificationRouter.shared.syncCoordinator = syncCoordinator
            AppNotificationRouter.shared.modelContext = modelContext
            AppNotificationRouter.shared.currentUserProvider = { currentUsers.first }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated, currentUser?.isRegisteredPublicly == true else { return }
            Task {
                await syncCoordinator.bootstrap(modelContext: modelContext, currentUser: currentUser)
            }
        }
        .onChange(of: currentUser?.isRegisteredPublicly) { _, isRegistered in
            guard authService.isAuthenticated, isRegistered == true else { return }
            Task {
                await syncCoordinator.bootstrap(modelContext: modelContext, currentUser: currentUser)
            }
        }
    }
}

struct LaunchLoadingView: View {
    var body: some View {
        ZStack {
            BMIGradient.header.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("🍔")
                    .font(.system(size: 56))
                ProgressView()
                    .tint(.white)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.previewContainer)
}
