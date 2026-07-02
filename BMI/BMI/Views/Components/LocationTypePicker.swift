import SwiftUI

struct LocationTypePicker: View {
    @Binding var selection: LocationType

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LocationType.allCases) { type in
                    Button {
                        selection = type
                    } label: {
                        Label(type.displayName, systemImage: type.icon)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selection == type ? Color.bmiRed : Color(.systemGray6))
                            .foregroundStyle(selection == type ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

#Preview {
    LocationTypePicker(selection: .constant(.urban))
}
