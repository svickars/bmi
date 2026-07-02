import SwiftUI

struct PurchasedItemsPicker: View {
    @Binding var selection: Set<PurchasedItem>

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(PurchasedItem.allCases) { item in
                Button {
                    if selection.contains(item) {
                        selection.remove(item)
                    } else {
                        selection.insert(item)
                    }
                } label: {
                    Text(item.displayName)
                        .font(BMITypography.ui(.caption, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection.contains(item) ? Color.bmiYellow.opacity(0.35) : Color.bmiSurface)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(
                                    selection.contains(item) ? Color.bmiBrown : Color.bmiBorder,
                                    lineWidth: selection.contains(item) ? 2 : 1
                                )
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    PurchasedItemsPicker(selection: .constant([.bigMac, .fries]))
        .padding()
        .background(BMIScreenBackground())
}
