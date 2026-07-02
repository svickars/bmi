import SwiftUI
import SwiftData

@main
struct BMIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            BigMacReport.self,
            UserProfile.self,
            ReportPhoto.self,
            AppSettings.self,
            FriendLink.self,
            ReportReaction.self,
            UserNotification.self
        ], isAutosaveEnabled: true)
    }
}
