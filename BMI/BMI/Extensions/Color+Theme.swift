import SwiftUI

extension Color {
    static let bmiYellow = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let bmiRed = Color(red: 0.86, green: 0.08, blue: 0.08)
    static let bmiBrown = Color(red: 0.45, green: 0.26, blue: 0.12)
    static let bmiCream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let bmiGreen = Color(red: 0.18, green: 0.55, blue: 0.24)

    static let bmiPaper = Color(red: 0.96, green: 0.95, blue: 0.89)
    static let bmiSurface = Color.white
    static let bmiInk = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let bmiMuted = Color(red: 0.42, green: 0.42, blue: 0.42)
    static let bmiBorder = Color(red: 0.45, green: 0.26, blue: 0.12).opacity(0.15)
    static let bmiSesame = Color(red: 0.97, green: 0.91, blue: 0.78)
    static let bmiPatty = Color(red: 0.36, green: 0.24, blue: 0.18)
    static let bmiCheese = Color(red: 1.0, green: 0.78, blue: 0.17)
    static let bmiLettuce = Color(red: 0.24, green: 0.55, blue: 0.25)
}

struct BMIGradient {
    static let header = LinearGradient(
        colors: [.bmiRed, .bmiBrown],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
