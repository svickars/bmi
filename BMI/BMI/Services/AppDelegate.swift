import CloudKit
import UIKit
import SwiftData
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // CloudKit uses the app's container; no manual token handling required.
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in
            SyncCoordinator.shared?.lastError = "Push registration failed: \(error.localizedDescription)"
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task { @MainActor in
            await AppNotificationRouter.shared.handleRemoteNotification(userInfo: userInfo)
            completionHandler(.newData)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            if let route = DeepLinkRouter.parseNotificationUserInfo(userInfo) {
                AppNavigationRouter.shared.open(route: route)
            }
            completionHandler()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

@MainActor
final class AppNotificationRouter: ObservableObject {
    static let shared = AppNotificationRouter()

    weak var syncCoordinator: SyncCoordinator?
    var modelContext: ModelContext?
    var currentUserProvider: (() -> UserProfile?)?

    func handleRemoteNotification(userInfo: [AnyHashable: Any]) async {
        guard let syncCoordinator,
              let modelContext,
              let currentUser = currentUserProvider?() else { return }

        await CloudKitNotificationService.shared.handleRemoteNotification(
            userInfo: userInfo,
            modelContext: modelContext,
            currentUser: currentUser,
            syncCoordinator: syncCoordinator
        )
    }
}

extension SyncCoordinator {
    private static weak var _shared: SyncCoordinator?

    static var shared: SyncCoordinator? {
        get { _shared }
        set { _shared = newValue }
    }
}
