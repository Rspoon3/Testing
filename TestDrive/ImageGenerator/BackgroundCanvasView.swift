import SwiftUI

/// Renders a 16:9 background canvas for the given style.
struct BackgroundCanvasView: View {
    let style: BackgroundStyle
    let seed: Int
    let colors: [Color]
    var symbolName: String?

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                backgroundGradient(for: style)
                patternOverlay(for: style, in: size)

                if let symbolName {
                    SymbolScatterPattern(
                        size: size,
                        rng: SeededRandom(seed: seed &+ 999),
                        symbolName: symbolName,
                        accentColor: .white
                    )
                }
            }
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipped()
    }

    // MARK: - Private Views

    @ViewBuilder
    private func backgroundGradient(for style: BackgroundStyle) -> some View {
        let c0 = colors.indices.contains(0) ? colors[0] : .clear
        let c1 = colors.indices.contains(1) ? colors[1] : .clear
        let c2 = colors.indices.contains(2) ? colors[2] : .clear
        let c3 = colors.indices.contains(3) ? colors[3] : .clear

        switch style {
        case .purplePlus:
            LinearGradient(colors: [c0, c1], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gradientBubbles:
            LinearGradient(colors: [c0, c1], startPoint: .leading, endPoint: .trailing)
        case .greenClovers:
            LinearGradient(colors: [c0, c1], startPoint: .top, endPoint: .bottom)
        case .mintBlobs:
            LinearGradient(colors: [c0, c1], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sunsetWaves:
            LinearGradient(colors: [c0, c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .oceanDots:
            LinearGradient(colors: [c0, c1], startPoint: .top, endPoint: .bottom)
        case .warmConfetti:
            LinearGradient(colors: [c0, c1], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neonGrid:
            LinearGradient(colors: [c0, c1], startPoint: .top, endPoint: .bottom)
        case .radialBurst:
            LinearGradient(colors: [c0, c1], startPoint: .top, endPoint: .bottom)
        case .waveform:
            LinearGradient(colors: [c0, c1], startPoint: .top, endPoint: .bottom)
        case .cosmicSpace:
            RadialGradient(colors: [c0, c1], center: .center, startRadius: 0, endRadius: 600)
        case .solidGradient:
            LinearGradient(colors: [c0, c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .meshGradient:
            MeshGradientBackground(
                topLeft: c0,
                topRight: c1,
                bottomLeft: c2,
                bottomRight: c3
            )
        }
    }

    @ViewBuilder
    private func patternOverlay(for style: BackgroundStyle, in size: CGSize) -> some View {
        let rng = SeededRandom(seed: seed)
        let accent = colors.indices.contains(2) ? colors[2] : .white

        switch style {
        case .purplePlus:
            PurplePlusPattern(size: size, rng: rng, accentColor: accent)
        case .gradientBubbles:
            GradientBubblesPattern(size: size, rng: rng)
        case .greenClovers:
            GreenCloversPattern(size: size, rng: rng, accentColor: accent)
        case .mintBlobs:
            MintBlobsPattern(size: size, rng: rng, accentColor: accent)
        case .sunsetWaves:
            SunsetWavesPattern(size: size, rng: rng)
        case .oceanDots:
            OceanDotsPattern(size: size, rng: rng, accentColor: accent)
        case .warmConfetti:
            WarmConfettiPattern(size: size, rng: rng)
        case .neonGrid:
            NeonGridPattern(size: size, rng: rng, accentColor: accent)
        case .radialBurst:
            RadialBurstPattern(size: size, rng: rng, accentColor: accent)
        case .waveform:
            WaveformPattern(size: size, rng: rng, accentColor: accent)
        case .cosmicSpace:
            CosmicSpacePattern(size: size, rng: rng, accentColor: accent)
        case .solidGradient, .meshGradient:
            EmptyView()
        }
    }
}

/// Renders a MeshGradient from four corner colors with blended interior points.
private struct MeshGradientBackground: View {
    let topLeft: Color
    let topRight: Color
    let bottomLeft: Color
    let bottomRight: Color

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                topLeft,    blend(topLeft, topRight),    topRight,
                blend(topLeft, bottomLeft), blend(topLeft, topRight, bottomLeft, bottomRight), blend(topRight, bottomRight),
                bottomLeft, blend(bottomLeft, bottomRight), bottomRight
            ]
        )
    }

    // MARK: - Private Helpers

    private func blend(_ colors: Color...) -> Color {
        let resolved = colors.map { $0.resolve(in: EnvironmentValues()) }
        let count = Float(resolved.count)
        let r = resolved.map(\.linearRed).reduce(0, +) / count
        let g = resolved.map(\.linearGreen).reduce(0, +) / count
        let b = resolved.map(\.linearBlue).reduce(0, +) / count
        return Color(red: Double(r), green: Double(g), blue: Double(b))
    }
}

#Preview {
    BackgroundCanvasView(
        style: .meshGradient,
        seed: 42,
        colors: BackgroundStyle.meshGradient.defaultColors.map(\.color),
        symbolName: "heart.fill"
    )
    .padding()
}
