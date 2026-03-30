import SwiftUI

/// Colorful floating circles/bubbles on a vibrant gradient background.
struct GradientBubblesPattern: View {
    let size: CGSize
    let rng: SeededRandom

    private let bubbleColors: [Color] = [
        .orange, .yellow, .pink, .green, .cyan, .mint, .white
    ]

    var body: some View {
        Canvas { context, canvasSize in
            let count = 25

            for _ in 0..<count {
                let x = rng.nextDouble(in: 0...Double(canvasSize.width))
                let y = rng.nextDouble(in: 0...Double(canvasSize.height))
                let radius = rng.nextDouble(in: 15...60)
                let opacity = rng.nextDouble(in: 0.15...0.45)
                let colorIndex = Int(rng.nextDouble() * Double(bubbleColors.count)) % bubbleColors.count
                let color = bubbleColors[colorIndex]

                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                let circle = Path(ellipseIn: rect)

                context.fill(circle, with: .color(color.opacity(opacity)))

                // Add a subtle inner highlight
                let highlightRect = CGRect(x: x - radius * 0.6, y: y - radius * 0.6, width: radius * 1.2, height: radius * 1.2)
                let highlight = Path(ellipseIn: highlightRect)
                context.fill(highlight, with: .color(.white.opacity(opacity * 0.3)))
            }
        }
    }
}
