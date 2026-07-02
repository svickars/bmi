import SwiftUI

struct TagFriendsView: View {
    let friends: [UserProfile]
    @Binding var selectedFriends: Set<UUID>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(friends, id: \.id) { friend in
                    Button {
                        toggle(friend.id)
                    } label: {
                        VStack(spacing: 6) {
                            Text(friend.avatarEmoji)
                                .font(.title2)
                                .frame(width: 52, height: 52)
                                .background(selectedFriends.contains(friend.id) ? Color.bmiYellow.opacity(0.4) : Color(.systemGray6))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedFriends.contains(friend.id) ? Color.bmiRed : .clear, lineWidth: 2)
                                )

                            Text(friend.displayName.components(separatedBy: " ").first ?? friend.displayName)
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

    private func toggle(_ id: UUID) {
        if selectedFriends.contains(id) {
            selectedFriends.remove(id)
        } else {
            selectedFriends.insert(id)
        }
    }
}

#Preview {
    TagFriendsView(friends: [], selectedFriends: .constant([]))
}
