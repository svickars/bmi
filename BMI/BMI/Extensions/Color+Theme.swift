import SwiftUI

extension Color {
    static let bmiYellow = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let bmiRed = Color(red: 0.86, green: 0.08, blue: 0.08)
    static let bmiBrown = Color(red: 0.45, green: 0.26, blue: 0.12)
    static let bmiCream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let bmiGreen = Color(red: 0.18, green: 0.55, blue: 0.24)
}

struct BMIGradient {
    static let header = LinearGradient(
        colors: [.bmiRed, .bmiBrown],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
