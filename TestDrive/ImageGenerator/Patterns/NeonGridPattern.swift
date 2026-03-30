import SwiftUI

/// Glowing neon grid lines with accent nodes on a dark background.
struct NeonGridPattern: View {
    let size: CGSize
    let rng: SeededRandom

    private let neonColors: [Color] = [
        .cyan, .pink, .purple, .mint, Color(red: 0.4, green: 1.0, blue: 0.6)
    ]

    var body: some View {
        Canvas { context, canvasSize in
            let spacing: CGFloat = 45

            // Grid lines
            let cols = Int(canvasSize.width / spacing) + 1
            let rows = Int(canvasSize.height / spacing) + 1

            for col in 0...cols {
                let x = CGFloat(col) * spacing
                var line = Path()
                line.move(to: CGPoint(x: x, y: 0))
                line.addLine(to: CGPoint(x: x, y: canvasSize.height))
                context.stroke(line, with: .color(.cyan.opacity(0.12)), lineWidth: 1)
            }

            for row in 0...rows {
                let y = CGFloat(row) * spacing
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: canvasSize.width, y: y))
                context.stroke(line, with: .color(.cyan.opacity(0.12)), lineWidth: 1)
            }

            // Glowing nodes at intersections
            for _ in 0..<15 {
                let col = Int(rng.nextDouble() * Double(cols))
                let row = Int(rng.nextDouble() * Double(rows))
                let x = CGFloat(col) * spacing
                let y = CGFloat(row) * spacing
                let colorIndex = Int(rng.nextDouble() * Double(neonColors.count)) % neonColors.count
                let glowSize = rng.nextDouble(in: 4...12)
                let opacity = rng.nextDouble(in: 0.3...0.7)

                // Outer glow
                let outerRect = CGRect(x: Double(x) - glowSize * 2, y: Double(y) - glowSize * 2, width: glowSize * 4, height: glowSize * 4)
                let outerGlow = Path(ellipseIn: outerRect)
                context.fill(outerGlow, with: .color(neonColors[colorIndex].opacity(opacity * 0.3)))

                // Inner bright dot
                let innerRect = CGRect(x: Double(x) - glowSize / 2, y: Double(y) - glowSize / 2, width: glowSize, height: glowSize)
                let innerDot = Path(ellipseIn: innerRect)
                context.fill(innerDot, with: .color(neonColors[colorIndex].opacity(opacity)))
            }

            // Accent lines
            for _ in 0..<4 {
                let startCol = Int(rng.nextDouble() * Double(cols))
                let startRow = Int(rng.nextDouble() * Double(rows))
                let endCol = Int(rng.nextDouble() * Double(cols))
                let endRow = startRow
                let colorIndex = Int(rng.nextDouble() * Double(neonColors.count)) % neonColors.count
                let opacity = rng.nextDouble(in: 0.15...0.35)

                var line = Path()
                line.move(to: CGPoint(x: CGFloat(startCol) * spacing, y: CGFloat(startRow) * spacing))
                line.addLine(to: CGPoint(x: CGFloat(endCol) * spacing, y: CGFloat(endRow) * spacing))
                context.stroke(line, with: .color(neonColors[colorIndex].opacity(opacity)), lineWidth: 2)
            }
        }
    }
}
