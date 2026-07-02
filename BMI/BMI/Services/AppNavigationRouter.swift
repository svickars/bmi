import Foundation
import SwiftUI

@MainActor
final class AppNavigationRouter: ObservableObject {
    static let shared = AppNavigationRouter()

    @Published var selectedTab = 0
    @Published var presentedReportID: UUID?
    @Published var presentedUsername: String?

    func open(route: DeepLinkRoute) {
        switch route {
        case .report(let id):
            selectedTab = 0
            presentedReportID = id
        case .userProfile(let username):
            presentedUsername = username
        case .notifications:
            selectedTab = 4
        case .friends:
            selectedTab = 4
        }
    }

    func openUserProfile(username: String) {
        presentedUsername = UsernameValidator.normalize(username)
    }

    func openReport(id: UUID) {
        selectedTab = 0
        presentedReportID = id
    }

    func dismissSheets() {
        presentedReportID = nil
        presentedUsername = nil
    }
}
