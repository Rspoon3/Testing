import SwiftUI

/// Renders a 16:9 background canvas for the given style.
struct BackgroundCanvasView: View {
    let style: BackgroundStyle
    let seed: Int

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                backgroundGradient(for: style, in: size)
                patternOverlay(for: style, in: size)
            }
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipped()
    }

    // MARK: - Private Views

    @ViewBuilder
    private func backgroundGradient(for style: BackgroundStyle, in size: CGSize) -> some View {
        switch style {
        case .purplePlus:
            LinearGradient(
                colors: [Color(red: 0.45, green: 0.2, blue: 0.75), Color(red: 0.35, green: 0.15, blue: 0.65)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .gradientBubbles:
            LinearGradient(
                colors: [Color(red: 0.6, green: 0.2, blue: 0.8), Color(red: 0.9, green: 0.3, blue: 0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )

        case .greenClovers:
            LinearGradient(
                colors: [Color(red: 0.9, green: 0.96, blue: 0.88), Color(red: 0.85, green: 0.94, blue: 0.82)],
                startPoint: .top,
                endPoint: .bottom
            )

        case .mintBlobs:
            LinearGradient(
                colors: [Color(red: 0.82, green: 0.95, blue: 0.88), Color(red: 0.75, green: 0.92, blue: 0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .sunsetWaves:
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.6, blue: 0.3), Color(red: 0.95, green: 0.35, blue: 0.5), Color(red: 0.6, green: 0.2, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .oceanDots:
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.6, blue: 0.85), Color(red: 0.15, green: 0.35, blue: 0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

        case .warmConfetti:
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.85, blue: 0.4), Color(red: 1.0, green: 0.65, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .neonGrid:
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.18), Color(red: 0.12, green: 0.05, blue: 0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private func patternOverlay(for style: BackgroundStyle, in size: CGSize) -> some View {
        let rng = SeededRandom(seed: seed)

        switch style {
        case .purplePlus:
            PurplePlusPattern(size: size, rng: rng)
        case .gradientBubbles:
            GradientBubblesPattern(size: size, rng: rng)
        case .greenClovers:
            GreenCloversPattern(size: size, rng: rng)
        case .mintBlobs:
            MintBlobsPattern(size: size, rng: rng)
        case .sunsetWaves:
            SunsetWavesPattern(size: size, rng: rng)
        case .oceanDots:
            OceanDotsPattern(size: size, rng: rng)
        case .warmConfetti:
            WarmConfettiPattern(size: size, rng: rng)
        case .neonGrid:
            NeonGridPattern(size: size, rng: rng)
        }
    }
}

#Preview {
    BackgroundCanvasView(style: .purplePlus, seed: 42)
        .padding()
}
