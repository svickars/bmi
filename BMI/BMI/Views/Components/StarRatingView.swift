import SwiftUI

struct StarRatingView: View {
    let rating: Int
    var maxRating: Int = 5
    var size: CGFloat = 16
    var interactive: Bool = false
    var onRatingChanged: ((Int) -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(star <= rating ? Color.bmiYellow : Color.gray.opacity(0.4))
                    .onTapGesture {
                        if interactive {
                            onRatingChanged?(star)
                        }
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rating) out of \(maxRating) stars")
    }
}

#Preview {
    StarRatingView(rating: 4, interactive: true)
}
