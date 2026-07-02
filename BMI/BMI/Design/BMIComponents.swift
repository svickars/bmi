import SwiftUI

struct BMIScreenBackground: View {
    var body: some View {
        Color.bmiPaper
            .ignoresSafeArea()
    }
}

struct BMICard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(Color.bmiSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.bmiBorder, lineWidth: 1)
            }
    }
}

struct BMIPillChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BMITypography.ui(.caption, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.bmiRed : Color.bmiSurface)
                .foregroundStyle(isSelected ? .white : Color.bmiInk)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(isSelected ? Color.bmiRed : Color.bmiBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct BMIPriceBadge: View {
    let text: String
    var diameter: CGFloat = 56

    var body: some View {
        Text(text)
            .font(BMITypography.data(diameter * 0.22, weight: .bold))
            .foregroundStyle(Color.bmiRed)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .frame(width: diameter, height: diameter)
            .background(Color.bmiSurface)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(Color.bmiRed.opacity(0.35), lineWidth: 1.5)
            }
    }
}

struct BMIPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(BMITypography.ui(.headline, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.bmiRed)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct BMILayerMark: View {
    var width: CGFloat = 220

    var body: some View {
        Image("BMIMark")
            .resizable()
            .scaledToFit()
            .frame(width: width, height: width)
            .accessibilityHidden(true)
    }
}

/// Full-bleed horizontal stripe background inspired by the BMI mark artwork.
/// Use for splash moments: sign-in, launch, photo-less report heroes.
struct BMIBurgerStripesBackground: View {
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                stripeBand(color: .bmiStripeBun, weight: 115.673, in: geo.size.height)
                stripeBand(color: .bmiStripeOlive, weight: 17.3259, in: geo.size.height)
                stripeBand(color: .bmiStripeCheese, weight: 17.3259, in: geo.size.height)
                lettuceBand(weight: 11, in: geo.size.height)
                stripeBand(color: .bmiStripePatty, weight: 73.2097, in: geo.size.height)
                stripeBand(color: .bmiStripeSauce, weight: 21.8017, in: geo.size.height)
                stripeBand(color: .bmiStripeBunMid, weight: 69, in: geo.size.height)
                stripeBand(color: .bmiStripeCheese, weight: 17.3259, in: geo.size.height)
                stripeBand(color: .bmiStripePatty, weight: 73.2097, in: geo.size.height)
                stripeBand(color: .bmiStripeOlive, weight: 17.3259, in: geo.size.height)
                stripeBand(color: .bmiStripeSauce, weight: 21.8017, in: geo.size.height)
                stripeBand(color: .bmiStripeBunMid, weight: 69, in: geo.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func stripeBand(color: Color, weight: CGFloat, in totalHeight: CGFloat) -> some View {
        color
            .frame(height: totalHeight * (weight / 524))
            .frame(maxWidth: .infinity)
    }

    private func lettuceBand(weight: CGFloat, in totalHeight: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                (index.isMultiple(of: 2) ? Color.bmiStripeLettuce : Color.bmiStripeLettuceDark)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: totalHeight * (weight / 524))
        .frame(maxWidth: .infinity)
    }
}

/// Softens full-bleed stripe backgrounds so foreground text and controls stay readable.
struct BMIMomentScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.28),
                .init(color: Color.bmiPaper.opacity(0.75), location: 0.62),
                .init(color: Color.bmiPaper.opacity(0.96), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct BMIBiteClipShape: Shape {
    var biteRadius: CGFloat = 36

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 16, height: 16))

        path.addEllipse(in: CGRect(
            x: rect.maxX - biteRadius * 0.85,
            y: rect.minY - biteRadius * 0.35,
            width: biteRadius * 1.1,
            height: biteRadius * 1.1
        ))
        path.addEllipse(in: CGRect(
            x: rect.maxX - biteRadius * 1.15,
            y: rect.midY - biteRadius * 0.55,
            width: biteRadius,
            height: biteRadius
        ))
        path.addEllipse(in: CGRect(
            x: rect.maxX - biteRadius * 0.65,
            y: rect.maxY - biteRadius * 0.75,
            width: biteRadius * 0.95,
            height: biteRadius * 0.95
        ))

        return path
    }
}

extension View {
    func bmiBiteClip() -> some View {
        clipShape(BMIBiteClipShape(), style: FillStyle(eoFill: true))
    }

    func bmiFormScreen() -> some View {
        scrollContentBackground(.hidden)
            .background(BMIScreenBackground())
    }
}

struct SelectableAvatarChip: View {
    let presentation: AvatarPresentation
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                BMIAvatarView(presentation: presentation, size: 52)
                    .overlay {
                        Circle()
                            .strokeBorder(isSelected ? Color.bmiRed : Color.clear, lineWidth: 2)
                    }

                Text(label)
                    .font(BMITypography.ui(.caption2))
                    .lineLimit(1)
                    .foregroundStyle(Color.bmiInk)
            }
            .frame(width: 64)
        }
        .buttonStyle(.plain)
    }
}
