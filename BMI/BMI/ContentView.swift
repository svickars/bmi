import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = AuthenticationService()
    @StateObject private var syncCoordinator = SyncCoordinator()
    @Query(filter: #Predicate<UserProfile> { $0.isCurrentUser }) private var currentUsers: [UserProfile]

    var body: some View {
        Group {
            if authService.isCheckingCredential {
                LaunchLoadingView()
            } else if authService.isAuthenticated {
                MainTabView()
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
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated else { return }
            Task {
                await syncCoordinator.bootstrap(modelContext: modelContext, currentUser: currentUsers.first)
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
