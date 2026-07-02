import SwiftUI

struct TagFriendsView: View {
    let friends: [UserProfile]
    @Binding var selectedFriends: Set<UUID>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(friends, id: \.id) { friend in
                    SelectableAvatarChip(
                        presentation: friend.avatarPresentation,
                        label: friend.displayName.components(separatedBy: " ").first ?? friend.displayName,
                        isSelected: selectedFriends.contains(friend.id)
                    ) {
                        toggle(friend.id)
                    }
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if selectedFriends.contains(id) {
            selectedFriends.remove(id)
        } else {
            selectedFriends.insert(id)
        }
    }
}
