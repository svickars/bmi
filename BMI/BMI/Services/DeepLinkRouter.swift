import Foundation

enum DeepLinkRoute: Equatable {
    case report(UUID)
    case userProfile(username: String)
    case notifications
    case friends
}

enum DeepLinkRouter {
    static let baseHost = "bmi.bysam.fun"

    static func reportURL(id: UUID) -> URL {
        URL(string: "https://\(baseHost)/report/\(id.uuidString.lowercased())")!
    }

    static func userURL(username: String) -> URL {
        let normalized = UsernameValidator.normalize(username)
        return URL(string: "https://\(baseHost)/u/\(normalized)")!
    }

    static func parse(url: URL) -> DeepLinkRoute? {
        guard let host = url.host?.lowercased(),
              host == baseHost || host == "www.\(baseHost)" else { return nil }

        let parts = url.pathComponents.filter { $0 != "/" }

        if parts.count >= 2, parts[0] == "report",
           let id = UUID(uuidString: parts[1]) {
            return .report(id)
        }

        if parts.count >= 2, parts[0] == "u" {
            let username = UsernameValidator.normalize(parts[1])
            guard UsernameValidator.validate(username) == nil else { return nil }
            return .userProfile(username: username)
        }

        return nil
    }

    static func parseNotificationUserInfo(_ userInfo: [AnyHashable: Any]) -> DeepLinkRoute? {
        guard let route = userInfo["route"] as? String else { return nil }

        switch route {
        case "report":
            guard let idString = userInfo["reportID"] as? String,
                  let id = UUID(uuidString: idString) else { return nil }
            return .report(id)
        case "notifications":
            return .notifications
        case "friends":
            return .friends
        default:
            return nil
        }
    }
}
