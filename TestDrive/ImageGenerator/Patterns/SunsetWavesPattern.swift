import SwiftUI

/// Layered sine waves on a warm sunset gradient.
struct SunsetWavesPattern: View {
    let size: CGSize
    let rng: SeededRandom

    var body: some View {
        Canvas { context, canvasSize in
            let waveCount = 5

            for i in 0..<waveCount {
                let baseY = Double(canvasSize.height) * (0.3 + Double(i) * 0.15)
                let amplitude = rng.nextDouble(in: 15...35)
                let frequency = rng.nextDouble(in: 0.008...0.02)
                let phase = rng.nextDouble(in: 0...(2 * .pi))
                let opacity = rng.nextDouble(in: 0.1...0.25)

                var path = Path()
                path.move(to: CGPoint(x: 0, y: canvasSize.height))

                for x in stride(from: 0, through: Double(canvasSize.width), by: 2) {
                    let y = baseY + sin(x * frequency + phase) * amplitude
                    if x == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }

                path.addLine(to: CGPoint(x: Double(canvasSize.width), y: Double(canvasSize.height)))
                path.addLine(to: CGPoint(x: 0, y: Double(canvasSize.height)))
                path.closeSubpath()

                context.fill(path, with: .color(.white.opacity(opacity)))
            }

            // Scattered small stars/sparkles
            for _ in 0..<15 {
                let x = rng.nextDouble(in: 0...Double(canvasSize.width))
                let y = rng.nextDouble(in: 0...Double(canvasSize.height * 0.6))
                let starSize = rng.nextDouble(in: 2...6)
                let opacity = rng.nextDouble(in: 0.2...0.5)

                let rect = CGRect(x: x - starSize / 2, y: y - starSize / 2, width: starSize, height: starSize)
                var star = Path()
                star.addEllipse(in: rect)
                context.fill(star, with: .color(.white.opacity(opacity)))
            }
        }
    }
}
