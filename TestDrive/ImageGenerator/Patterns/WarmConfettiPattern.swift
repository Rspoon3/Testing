import SwiftUI

/// Scattered confetti rectangles and diamonds on a warm yellow-orange gradient.
struct WarmConfettiPattern: View {
    let size: CGSize
    let rng: SeededRandom

    private let confettiColors: [Color] = [
        .red, .orange, .pink, .white, .yellow,
        Color(red: 0.9, green: 0.4, blue: 0.2),
        Color(red: 1.0, green: 0.5, blue: 0.6)
    ]

    var body: some View {
        Canvas { context, canvasSize in
            let count = 35

            for _ in 0..<count {
                let x = rng.nextDouble(in: 0...Double(canvasSize.width))
                let y = rng.nextDouble(in: 0...Double(canvasSize.height))
                let w = rng.nextDouble(in: 6...16)
                let h = rng.nextDouble(in: 12...28)
                let rotation = rng.nextDouble(in: 0...360)
                let opacity = rng.nextDouble(in: 0.15...0.4)
                let colorIndex = Int(rng.nextDouble() * Double(confettiColors.count)) % confettiColors.count

                let transform = CGAffineTransform.identity
                    .translatedBy(x: x, y: y)
                    .rotated(by: rotation * .pi / 180)

                let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
                let confetti = Path(roundedRect: rect, cornerRadius: 2).applying(transform)

                context.fill(confetti, with: .color(confettiColors[colorIndex].opacity(opacity)))
            }
        }
    }
}
