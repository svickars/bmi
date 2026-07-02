import SwiftUI

struct BMIAvatarView: View {
    let presentation: AvatarPresentation
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(presentation.backgroundColor)

            switch presentation.style {
            case .emoji:
                Text(presentation.emoji)
                    .font(.system(size: size * 0.46))
            case .initials:
                Text(presentation.displayInitials)
                    .font(BMITypography.data(size * 0.34, weight: .bold))
                    .foregroundStyle(initialsForeground)
            }
        }
        .frame(width: size, height: size)
        .overlay {
            Circle()
                .strokeBorder(Color.bmiBorder, lineWidth: 1)
        }
        .accessibilityLabel("Avatar")
    }

    private var initialsForeground: Color {
        presentation.backgroundHex.uppercased() == "F7E8C8"
            || presentation.backgroundHex.uppercased() == "FFC72C"
            ? Color.bmiInk
            : .white
    }
}

extension BMIAvatarView {
    init(user: UserProfile, size: CGFloat = 44) {
        self.init(presentation: user.avatarPresentation, size: size)
    }

    init(user: PublicUserDTO, size: CGFloat = 44) {
        self.init(presentation: user.avatarPresentation, size: size)
    }

    init(friend: FriendLink, size: CGFloat = 44) {
        self.init(
            presentation: AvatarPresentation(
                style: .emoji,
                emoji: friend.friendAvatarEmoji.isEmpty ? "🍔" : friend.friendAvatarEmoji,
                initials: AvatarAppearance.defaultInitials(from: friend.friendDisplayName),
                backgroundHex: AvatarAppearance.defaultBackgroundHex(for: .emoji)
            ),
            size: size
        )
    }
}
