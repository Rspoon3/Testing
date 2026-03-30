import SwiftUI

/// Repeating plus/cross symbols on a purple background, inspired by Fetch promo banners.
struct PurplePlusPattern: View {
    let size: CGSize
    let rng: SeededRandom

    var body: some View {
        Canvas { context, canvasSize in
            let spacing: CGFloat = 50
            let cols = Int(canvasSize.width / spacing) + 2
            let rows = Int(canvasSize.height / spacing) + 2

            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * spacing + (row.isMultiple(of: 2) ? spacing / 2 : 0)
                    let y = CGFloat(row) * spacing
                    let opacity = rng.nextDouble(in: 0.08...0.2)
                    let scale = rng.nextDouble(in: 0.6...1.0)
                    let plusSize: CGFloat = 18 * scale

                    let center = CGPoint(x: x, y: y)
                    var path = Path()
                    let thickness: CGFloat = plusSize * 0.3
                    path.addRoundedRect(
                        in: CGRect(x: center.x - plusSize / 2, y: center.y - thickness / 2, width: plusSize, height: thickness),
                        cornerSize: CGSize(width: thickness / 2, height: thickness / 2)
                    )
                    path.addRoundedRect(
                        in: CGRect(x: center.x - thickness / 2, y: center.y - plusSize / 2, width: thickness, height: plusSize),
                        cornerSize: CGSize(width: thickness / 2, height: thickness / 2)
                    )

                    context.fill(path, with: .color(.white.opacity(opacity)))
                }
            }
        }
    }
}
