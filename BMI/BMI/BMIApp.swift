import SwiftUI
import SwiftData

@main
struct BMIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            BigMacReport.self,
            UserProfile.self,
            ReportPhoto.self,
            AppSettings.self,
            FriendLink.self
        ], isAutosaveEnabled: true)
    }
}
