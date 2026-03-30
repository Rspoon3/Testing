import SwiftUI

/// Scattered shamrock/clover shapes on a light green background.
struct GreenCloversPattern: View {
    let size: CGSize
    let rng: SeededRandom
    var accentColor: Color = Color(red: 0.3, green: 0.65, blue: 0.35)

    var body: some View {
        Canvas { context, canvasSize in
            let count = 30

            for _ in 0..<count {
                let x = rng.nextDouble(in: 0...Double(canvasSize.width))
                let y = rng.nextDouble(in: 0...Double(canvasSize.height))
                let scale = rng.nextDouble(in: 0.4...1.2)
                let opacity = rng.nextDouble(in: 0.08...0.25)
                let leafSize: CGFloat = 12 * scale
                context.opacity = opacity

                // Draw a simple 3-leaf clover using circles
                let offsets: [(CGFloat, CGFloat)] = [
                    (0, -leafSize),
                    (-leafSize * 0.866, leafSize * 0.5),
                    (leafSize * 0.866, leafSize * 0.5)
                ]

                for offset in offsets {
                    let leafRect = CGRect(
                        x: x + offset.0 - leafSize / 2,
                        y: y + offset.1 - leafSize / 2,
                        width: leafSize,
                        height: leafSize
                    )
                    let leaf = Path(ellipseIn: leafRect)
                    context.fill(leaf, with: .color(accentColor))
                }

                // Stem
                var stem = Path()
                stem.move(to: CGPoint(x: x, y: y))
                stem.addLine(to: CGPoint(x: x, y: y + leafSize * 1.8))
                context.stroke(stem, with: .color(accentColor), lineWidth: 2 * scale)

                context.opacity = 1
            }
        }
    }
}
