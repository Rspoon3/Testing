import SwiftUI

/// Concentric dot rings and scattered dots on an ocean blue gradient.
struct OceanDotsPattern: View {
    let size: CGSize
    let rng: SeededRandom

    var body: some View {
        Canvas { context, canvasSize in
            // Background scattered dots
            for _ in 0..<40 {
                let x = rng.nextDouble(in: 0...Double(canvasSize.width))
                let y = rng.nextDouble(in: 0...Double(canvasSize.height))
                let radius = rng.nextDouble(in: 2...8)
                let opacity = rng.nextDouble(in: 0.1...0.35)

                let dot = Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                context.fill(dot, with: .color(.white.opacity(opacity)))
            }

            // Concentric ring clusters
            let clusterCount = 3
            for _ in 0..<clusterCount {
                let cx = rng.nextDouble(in: 20...Double(canvasSize.width - 20))
                let cy = rng.nextDouble(in: 20...Double(canvasSize.height - 20))
                let rings = Int(rng.nextDouble(in: 3...5))

                for ring in 1...rings {
                    let radius = Double(ring) * 18
                    let dotsInRing = ring * 6
                    let opacity = rng.nextDouble(in: 0.08...0.2)

                    for dot in 0..<dotsInRing {
                        let angle = Double(dot) * (2 * .pi / Double(dotsInRing))
                        let dx = cx + cos(angle) * radius
                        let dy = cy + sin(angle) * radius
                        let dotSize = rng.nextDouble(in: 3...6)

                        let dotPath = Path(ellipseIn: CGRect(x: dx - dotSize / 2, y: dy - dotSize / 2, width: dotSize, height: dotSize))
                        context.fill(dotPath, with: .color(.cyan.opacity(opacity)))
                    }
                }
            }
        }
    }
}
