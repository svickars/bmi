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

    private var height: CGFloat { width * 0.55 }

    var body: some View {
        VStack(spacing: width * 0.028) {
            layerBand(color: .bmiSesame, height: height * 0.18, topRadius: width * 0.08)
                .overlay(alignment: .top) {
                    HStack(spacing: width * 0.04) {
                        ForEach(0..<5, id: \.self) { _ in
                            Circle()
                                .fill(Color.white.opacity(0.85))
                                .frame(width: width * 0.018, height: width * 0.018)
                        }
                    }
                    .padding(.top, height * 0.04)
                }
            layerBand(color: .bmiPatty, height: height * 0.09)
            layerBand(color: .bmiSesame, height: height * 0.05)
            layerBand(color: .bmiPatty, height: height * 0.09)
            layerBand(color: .bmiLettuce, height: height * 0.08, wavy: true)
            layerBand(color: .bmiPatty, height: height * 0.09)
            layerBand(color: .bmiCheese, height: height * 0.07)
            layerBand(color: .bmiLettuce, height: height * 0.08, wavy: true)
            layerBand(color: .bmiSesame, height: height * 0.14, bottomRadius: width * 0.06)
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func layerBand(
        color: Color,
        height: CGFloat,
        topRadius: CGFloat = 0,
        bottomRadius: CGFloat = 0,
        wavy: Bool = false
    ) -> some View {
        if wavy {
            WavyLayerBand(color: color)
                .frame(height: height)
        } else {
            RoundedRectangle(cornerRadius: min(topRadius, bottomRadius, height / 2), style: .continuous)
                .fill(color)
                .frame(height: height)
        }
    }
}

private struct WavyLayerBand: View {
    let color: Color

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: h * 0.45))
                path.addQuadCurve(to: CGPoint(x: w * 0.75, y: h), control: CGPoint(x: w, y: h))
                path.addQuadCurve(to: CGPoint(x: w * 0.25, y: h * 0.55), control: CGPoint(x: w * 0.5, y: h * 1.1))
                path.addQuadCurve(to: CGPoint(x: 0, y: h * 0.4), control: CGPoint(x: w * 0.05, y: h))
                path.closeSubpath()
            }
            .fill(color)
        }
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

extension Shape {
    func bmiBiteClip() -> some View {
        clipShape(BMIBiteClipShape(), style: FillStyle(eoFill: true))
    }
}
