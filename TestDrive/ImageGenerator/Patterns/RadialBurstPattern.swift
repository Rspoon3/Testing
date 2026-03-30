import SwiftUI

/// Alternating radial rays bursting from the center, inspired by RadialBurstView.
struct RadialBurstPattern: View {
    let size: CGSize
    let rng: SeededRandom

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let maxRadius = sqrt(pow(canvasSize.width, 2) + pow(canvasSize.height, 2)) / 2
            let rayCount = Int(rng.nextDouble(in: 30...60))
            let rotationOffset = rng.nextDouble(in: 0...(2 * .pi))

            for i in 0..<rayCount {
                let angle1 = Double(i) / Double(rayCount) * 2 * .pi + rotationOffset
                let angle2 = Double(i + 1) / Double(rayCount) * 2 * .pi + rotationOffset

                let point1 = CGPoint(
                    x: center.x + cos(angle1) * maxRadius,
                    y: center.y + sin(angle1) * maxRadius
                )
                let point2 = CGPoint(
                    x: center.x + cos(angle2) * maxRadius,
                    y: center.y + sin(angle2) * maxRadius
                )

                var path = Path()
                path.move(to: center)
                path.addLine(to: point1)
                path.addLine(to: point2)
                path.closeSubpath()

                let opacity = i.isMultiple(of: 2) ? 0.25 : 0.1
                context.fill(path, with: .color(.white.opacity(opacity)))
            }

            // Add subtle concentric ring accents
            let ringCount = Int(rng.nextDouble(in: 3...6))
            for i in 1...ringCount {
                let radius = maxRadius * Double(i) / Double(ringCount + 1)
                let ringRect = CGRect(
                    x: Double(center.x) - radius,
                    y: Double(center.y) - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                let ring = Path(ellipseIn: ringRect)
                let opacity = rng.nextDouble(in: 0.05...0.12)
                context.stroke(ring, with: .color(.white.opacity(opacity)), lineWidth: 1.5)
            }
        }
    }
}
