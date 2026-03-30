import SwiftUI

/// Deep space scene with stars, nebula clouds, and planets for an "out of this world" feel.
struct CosmicSpacePattern: View {
    let size: CGSize
    let rng: SeededRandom
    var accentColor: Color = Color(red: 0.4, green: 0.1, blue: 0.6)

    var body: some View {
        Canvas { context, canvasSize in
            let width = Double(canvasSize.width)
            let height = Double(canvasSize.height)

            drawStars(context: context, width: width, height: height)
            drawNebulaClouds(context: context, width: width, height: height)
            drawPlanets(context: context, width: width, height: height)
            drawShootingStar(context: context, width: width, height: height)
        }
    }

    // MARK: - Private Helpers

    private func drawStars(context: GraphicsContext, width: Double, height: Double) {
        for _ in 0..<120 {
            let x = rng.nextDouble(in: 0...width)
            let y = rng.nextDouble(in: 0...height)
            let starSize = rng.nextDouble(in: 1...3.5)
            let brightness = rng.nextDouble(in: 0.3...1.0)

            let dot = Path(ellipseIn: CGRect(x: x - starSize / 2, y: y - starSize / 2, width: starSize, height: starSize))
            context.fill(dot, with: .color(.white.opacity(brightness)))

            if brightness > 0.75 {
                let glowSize = starSize * 4
                let glow = Path(ellipseIn: CGRect(x: x - glowSize / 2, y: y - glowSize / 2, width: glowSize, height: glowSize))
                context.fill(glow, with: .color(.white.opacity(brightness * 0.15)))
            }
        }
    }

    private func drawNebulaClouds(context: GraphicsContext, width: Double, height: Double) {
        let nebulaColors: [Color] = [
            accentColor,
            accentColor.opacity(0.8),
            Color(red: 0.6, green: 0.15, blue: 0.4),
            Color(red: 0.1, green: 0.4, blue: 0.5)
        ]

        for _ in 0..<6 {
            let cx = rng.nextDouble(in: -50...width + 50)
            let cy = rng.nextDouble(in: -30...height + 30)
            let w = rng.nextDouble(in: 100...300)
            let h = rng.nextDouble(in: 60...180)
            let opacity = rng.nextDouble(in: 0.06...0.18)
            let colorIndex = Int(rng.nextDouble() * Double(nebulaColors.count)) % nebulaColors.count

            let cloud = Path(ellipseIn: CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h))
            context.fill(cloud, with: .color(nebulaColors[colorIndex].opacity(opacity)))
        }
    }

    private func drawPlanets(context: GraphicsContext, width: Double, height: Double) {
        let planetCount = Int(rng.nextDouble(in: 2...4))

        let planetColors: [(Color, Color)] = [
            (Color(red: 0.7, green: 0.4, blue: 0.2), Color(red: 0.5, green: 0.25, blue: 0.1)),
            (Color(red: 0.3, green: 0.5, blue: 0.8), Color(red: 0.15, green: 0.3, blue: 0.6)),
            (Color(red: 0.8, green: 0.6, blue: 0.3), Color(red: 0.6, green: 0.4, blue: 0.15)),
            (Color(red: 0.6, green: 0.3, blue: 0.5), Color(red: 0.4, green: 0.15, blue: 0.35))
        ]

        for i in 0..<planetCount {
            let cx = rng.nextDouble(in: width * 0.1...width * 0.9)
            let cy = rng.nextDouble(in: height * 0.15...height * 0.85)
            let radius = rng.nextDouble(in: 15...45)
            let colorPair = planetColors[i % planetColors.count]

            let planetRect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
            let planet = Path(ellipseIn: planetRect)
            context.fill(planet, with: .color(colorPair.0.opacity(0.8)))

            let shadowOffset = radius * 0.3
            let shadowRect = CGRect(x: cx - radius + shadowOffset, y: cy - radius, width: radius * 2, height: radius * 2)
            let shadow = Path(ellipseIn: shadowRect)
            context.fill(shadow, with: .color(colorPair.1.opacity(0.5)))

            let highlightSize = radius * 0.5
            let highlightRect = CGRect(x: cx - radius * 0.5, y: cy - radius * 0.5, width: highlightSize, height: highlightSize)
            let highlight = Path(ellipseIn: highlightRect)
            context.fill(highlight, with: .color(.white.opacity(0.15)))

            if i == 0 {
                let ringWidth = radius * 2.5
                let ringHeight = radius * 0.5
                var ring = Path()
                ring.addEllipse(in: CGRect(x: cx - ringWidth, y: cy - ringHeight / 2, width: ringWidth * 2, height: ringHeight))
                context.stroke(ring, with: .color(.white.opacity(0.2)), lineWidth: 2)
            }
        }
    }

    private func drawShootingStar(context: GraphicsContext, width: Double, height: Double) {
        let startX = rng.nextDouble(in: width * 0.3...width * 0.9)
        let startY = rng.nextDouble(in: 0...height * 0.3)
        let length = rng.nextDouble(in: 60...120)
        let angle = rng.nextDouble(in: 0.3...0.8)

        var trail = Path()
        trail.move(to: CGPoint(x: startX, y: startY))
        trail.addLine(to: CGPoint(x: startX - cos(angle) * length, y: startY + sin(angle) * length))
        context.stroke(trail, with: .color(.white.opacity(0.5)), lineWidth: 1.5)

        let headSize: Double = 3
        let head = Path(ellipseIn: CGRect(x: startX - headSize / 2, y: startY - headSize / 2, width: headSize, height: headSize))
        context.fill(head, with: .color(.white.opacity(0.8)))
    }
}
