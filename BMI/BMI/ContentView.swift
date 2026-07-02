import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = AuthenticationService()
    @StateObject private var syncCoordinator = SyncCoordinator()
    @StateObject private var navigationRouter = AppNavigationRouter.shared
    @Query(filter: #Predicate<UserProfile> { $0.isCurrentUser }) private var currentUsers: [UserProfile]

    private var currentUser: UserProfile? { currentUsers.first }

    var body: some View {
        Group {
            if authService.isCheckingCredential {
                LaunchLoadingView()
            } else if authService.isAuthenticated {
                if authService.hasPublicProfile {
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
        .environmentObject(navigationRouter)
        .onOpenURL { url in
            if let route = DeepLinkRouter.parse(url: url) {
                navigationRouter.open(route: route)
            }
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL,
                  let route = DeepLinkRouter.parse(url: url) else { return }
            navigationRouter.open(route: route)
        }
        .onAppear {
            authService.configure(modelContext: modelContext)
            authService.checkExistingCredential()
            authService.refreshPublicProfileStatus(from: modelContext)
            _ = AppSettingsStore.current(in: modelContext)

            AppNotificationRouter.shared.syncCoordinator = syncCoordinator
            AppNotificationRouter.shared.modelContext = modelContext
            AppNotificationRouter.shared.currentUserProvider = { currentUsers.first }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated, authService.hasPublicProfile else { return }
            Task {
                await syncCoordinator.bootstrap(modelContext: modelContext, currentUser: currentUser)
            }
        }
        .onChange(of: authService.hasPublicProfile) { _, isRegistered in
            guard authService.isAuthenticated, isRegistered else { return }
            authService.refreshPublicProfileStatus(from: modelContext)
            Task {
                await syncCoordinator.bootstrap(modelContext: modelContext, currentUser: currentUser)
            }
        }
    }
}

struct LaunchLoadingView: View {
    var body: some View {
        ZStack {
            BMIBurgerStripesBackground()

            VStack(spacing: 24) {
                BMILayerMark(width: 140)
                ProgressView()
                    .tint(.bmiStripePatty)
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.previewContainer)
        .environmentObject(AppNavigationRouter.shared)
}
