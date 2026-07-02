import SwiftUI

enum AvatarStyle: String, Codable, CaseIterable {
    case emoji
    case initials

    var displayName: String {
        switch self {
        case .emoji: "Emoji"
        case .initials: "Initials"
        }
    }
}

enum AvatarAppearance {
    static let presetBackgroundHexes = [
        "DC143C", // bmiRed
        "FFC72C", // bmiCheese
        "5C3D2E", // bmiPatty
        "3D8B40", // bmiLettuce
        "F7E8C8", // bmiSesame
        "1A1A1A", // ink
        "6B7280", // slate
        "2563EB", // blue
        "9333EA", // purple
        "F472B6"  // pink
    ]

    static func defaultInitials(from displayName: String) -> String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(trimmed.prefix(2)).uppercased()
    }

    static func sanitizedInitials(_ raw: String) -> String {
        String(raw.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(2))
    }

    static func backgroundColor(from hex: String) -> Color {
        Color(hex: hex) ?? .bmiRed
    }

    static func defaultBackgroundHex(for style: AvatarStyle) -> String {
        switch style {
        case .emoji: "F7E8C8"
        case .initials: "DC143C"
        }
    }
}

extension Color {
    init?(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "#", with: "")
        guard sanitized.count == 6, let value = UInt64(sanitized, radix: 16) else { return nil }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    var hexString: String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "DC143C"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}

import UIKit

struct AvatarPresentation {
    let style: AvatarStyle
    let emoji: String
    let initials: String
    let backgroundHex: String

    var backgroundColor: Color {
        AvatarAppearance.backgroundColor(from: backgroundHex)
    }

    var displayInitials: String {
        let value = AvatarAppearance.sanitizedInitials(initials)
        return value.isEmpty ? "BM" : value
    }
}

extension UserProfile {
    var avatarStyle: AvatarStyle {
        get { AvatarStyle(rawValue: avatarStyleRaw) ?? .emoji }
        set { avatarStyleRaw = newValue.rawValue }
    }

    var avatarPresentation: AvatarPresentation {
        AvatarPresentation(
            style: avatarStyle,
            emoji: avatarEmoji.isEmpty ? "🍔" : avatarEmoji,
            initials: avatarInitials.isEmpty
                ? AvatarAppearance.defaultInitials(from: displayName)
                : avatarInitials,
            backgroundHex: avatarBackgroundHex.isEmpty
                ? AvatarAppearance.defaultBackgroundHex(for: avatarStyle)
                : avatarBackgroundHex
        )
    }
}

extension PublicUserDTO {
    var avatarPresentation: AvatarPresentation {
        AvatarPresentation(
            style: avatarStyle,
            emoji: avatarEmoji.isEmpty ? "🍔" : avatarEmoji,
            initials: avatarInitials.isEmpty
                ? AvatarAppearance.defaultInitials(from: displayName)
                : avatarInitials,
            backgroundHex: avatarBackgroundHex.isEmpty
                ? AvatarAppearance.defaultBackgroundHex(for: avatarStyle)
                : avatarBackgroundHex
        )
    }
}
