import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = AuthenticationService()

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
        .onAppear {
            authService.configure(modelContext: modelContext)
            authService.checkExistingCredential()
            _ = AppSettingsStore.current(in: modelContext)
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
