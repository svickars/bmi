import SwiftUI

struct TagLinkedFriendsView: View {
    let friends: [FriendLink]
    @Binding var selectedFriendAppleUserIDs: Set<String>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(friends, id: \.id) { friend in
                    Button {
                        toggle(friend.friendAppleUserID)
                    } label: {
                        VStack(spacing: 6) {
                            Text(friend.friendAvatarEmoji)
                                .font(.title2)
                                .frame(width: 52, height: 52)
                                .background(selectedFriendAppleUserIDs.contains(friend.friendAppleUserID) ? Color.bmiYellow.opacity(0.4) : Color(.systemGray6))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedFriendAppleUserIDs.contains(friend.friendAppleUserID) ? Color.bmiRed : .clear, lineWidth: 2)
                                )

                            Text(friend.friendDisplayName.components(separatedBy: " ").first ?? friend.friendDisplayName)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                        }
                        .frame(width: 64)
                    }
                    .buttonStyle(.plain)
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
