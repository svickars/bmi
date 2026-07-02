import SwiftUI

struct TagLinkedFriendsView: View {
    let friends: [FriendLink]
    @Binding var selectedFriendAppleUserIDs: Set<String>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(friends, id: \.id) { friend in
                    SelectableAvatarChip(
                        presentation: AvatarPresentation(
                            style: .emoji,
                            emoji: friend.friendAvatarEmoji.isEmpty ? "🍔" : friend.friendAvatarEmoji,
                            initials: AvatarAppearance.defaultInitials(from: friend.friendDisplayName),
                            backgroundHex: AvatarAppearance.defaultBackgroundHex(for: .emoji)
                        ),
                        label: friend.friendDisplayName.components(separatedBy: " ").first ?? friend.friendDisplayName,
                        isSelected: selectedFriendAppleUserIDs.contains(friend.friendAppleUserID)
                    ) {
                        toggle(friend.friendAppleUserID)
                    }
                }
            }
        }
    }

    private func toggle(_ appleUserID: String) {
        if selectedFriendAppleUserIDs.contains(appleUserID) {
            selectedFriendAppleUserIDs.remove(appleUserID)
        } else {
            selectedFriendAppleUserIDs.insert(appleUserID)
        }
    }
}
