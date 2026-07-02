import SwiftUI

enum BMITypography {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func ui(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight)
    }

    static func data(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct BMISectionHeader: View {
    let title: String
    var showRule: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(BMITypography.display(28))
                .foregroundStyle(Color.bmiInk)

            if showRule {
                Rectangle()
                    .fill(Color.bmiRed)
                    .frame(width: 40, height: 2)
            }
        }
    }
}
