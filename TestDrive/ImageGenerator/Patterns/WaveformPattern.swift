import SwiftUI

/// Layered sine waveforms with parabolic amplitude envelope, inspired by the waveform branch.
struct WaveformPattern: View {
    let size: CGSize
    let rng: SeededRandom

    var body: some View {
        Canvas { context, canvasSize in
            let width = Double(canvasSize.width)
            let height = Double(canvasSize.height)
            let midHeight = height / 2
            let midWidth = width / 2
            let waveCount = 10

            for i in 0..<waveCount {
                let strength = rng.nextDouble(in: 30...80)
                let frequency = rng.nextDouble(in: 3...12)
                let phase = rng.nextDouble(in: 0...(2 * .pi))
                let yOffset = Double(i) * 8
                let wavelength = width / frequency
                let opacity = Double(waveCount - i) / Double(waveCount) * 0.4

                var path = Path()

                for x in stride(from: 0, through: width, by: 2) {
                    let relativeX = x / wavelength
                    let distanceFromMid = x - midWidth
                    let normalDistance = distanceFromMid / midWidth
                    let parabola = -(normalDistance * normalDistance) + 1
                    let y = parabola * strength * sin(relativeX + phase) + midHeight + yOffset

                    if x == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }

                context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: 3)
            }

            // Scattered small glow dots along the waves
            for _ in 0..<20 {
                let x = rng.nextDouble(in: 0...width)
                let y = rng.nextDouble(in: midHeight - 60...midHeight + 60)
                let dotSize = rng.nextDouble(in: 2...5)
                let opacity = rng.nextDouble(in: 0.15...0.4)

                let dot = Path(ellipseIn: CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize))
                context.fill(dot, with: .color(.cyan.opacity(opacity)))
            }
        }
    }
}
