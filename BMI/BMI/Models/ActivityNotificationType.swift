import Foundation

enum ActivityNotificationType: String, Codable, CaseIterable {
    case friendReport
    case taggedInReport
    case reaction

    var displayName: String {
        switch self {
        case .friendReport: "Friend Report"
        case .taggedInReport: "Tagged You"
        case .reaction: "Reaction"
        }
    }

    var icon: String {
        switch self {
        case .friendReport: "takeoutbag.and.cup.and.straw.fill"
        case .taggedInReport: "person.crop.circle.badge.plus"
        case .reaction: "heart.fill"
        }
    }
}

enum ReactionEmoji: String, CaseIterable, Identifiable {
    case love = "❤️"
    case thumbsUp = "👍"
    case fire = "🔥"
    case yum = "😋"
    case burger = "🍔"

    var id: String { rawValue }
}
