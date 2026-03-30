import SwiftUI

/// Scatters a repeating SF Symbol across the canvas at varying sizes and opacities.
struct SymbolScatterPattern: View {
    let size: CGSize
    let rng: SeededRandom
    let symbolName: String
    var accentColor: Color = .white

    var body: some View {
        Canvas { context, canvasSize in
            let image = Image(systemName: symbolName)
            let resolved = context.resolve(image)

            let count = 35

            for _ in 0..<count {
                let x = rng.nextDouble(in: 0...Double(canvasSize.width))
                let y = rng.nextDouble(in: 0...Double(canvasSize.height))
                let scale = rng.nextDouble(in: 0.6...2.0)
                let opacity = rng.nextDouble(in: 0.08...0.3)
                let rotation = Angle.degrees(rng.nextDouble(in: -20...20))

                var copy = context
                copy.opacity = opacity
                copy.translateBy(x: x, y: y)
                copy.rotate(by: rotation)
                copy.scaleBy(x: scale, y: scale)

                copy.draw(resolved, at: .zero)
            }
        }
        .foregroundStyle(accentColor)
    }
}
