import SwiftUI

/// Organic blob and flower shapes on a mint background.
struct MintBlobsPattern: View {
    let size: CGSize
    let rng: SeededRandom

    var body: some View {
        Canvas { context, canvasSize in
            let blobCount = 12
            let flowerCount = 8

            // Organic blobs
            for _ in 0..<blobCount {
                let x = rng.nextDouble(in: -30...Double(canvasSize.width + 30))
                let y = rng.nextDouble(in: -30...Double(canvasSize.height + 30))
                let w = rng.nextDouble(in: 40...120)
                let h = rng.nextDouble(in: 40...100)
                let opacity = rng.nextDouble(in: 0.1...0.25)

                let rect = CGRect(x: x, y: y, width: w, height: h)
                let blob = Path(roundedRect: rect, cornerRadius: min(w, h) * 0.4)
                context.fill(blob, with: .color(Color(red: 0.55, green: 0.85, blue: 0.65).opacity(opacity)))
            }

            // Simple flower shapes
            for _ in 0..<flowerCount {
                let cx = rng.nextDouble(in: 0...Double(canvasSize.width))
                let cy = rng.nextDouble(in: 0...Double(canvasSize.height))
                let petalSize = rng.nextDouble(in: 8...20)
                let opacity = rng.nextDouble(in: 0.12...0.3)
                let petalCount = 5

                for i in 0..<petalCount {
                    let angle = Double(i) * (2 * .pi / Double(petalCount))
                    let px = cx + cos(angle) * petalSize * 1.2
                    let py = cy + sin(angle) * petalSize * 1.2
                    let petalRect = CGRect(x: px - petalSize / 2, y: py - petalSize / 2, width: petalSize, height: petalSize)
                    let petal = Path(ellipseIn: petalRect)
                    context.fill(petal, with: .color(Color(red: 0.4, green: 0.75, blue: 0.55).opacity(opacity)))
                }
            }
        }
    }
}
