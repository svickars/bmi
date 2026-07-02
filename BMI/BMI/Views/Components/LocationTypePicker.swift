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
                            .font(BMITypography.ui(.caption, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selection == type ? Color.bmiRed : Color.bmiSurface)
                            .foregroundStyle(selection == type ? .white : Color.bmiInk)
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .strokeBorder(
                                        selection == type ? Color.bmiRed : Color.bmiBorder,
                                        lineWidth: 1
                                    )
                            }
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
        .padding()
        .background(BMIScreenBackground())
}
