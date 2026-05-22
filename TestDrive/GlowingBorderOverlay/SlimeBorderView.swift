//
//  SlimeBorderView.swift
//  TestDrive
//

import SwiftUI

/// Dripping bright-green slime hanging from the top of the screen. A solid
/// ooze layer covers the top edge, with rounded lobes drooping along the
/// underside, stalactites stretching downward into smooth teardrops, and
/// detached droplets falling away — all driven by ``SlimeSimulation``.
struct SlimeBorderView: View {
    @State private var simulation = SlimeSimulation()

    /// The main slime body color — a bright sickly green.
    private let slimeColor: Color = Color(red: 0.32, green: 0.85, blue: 0.20)

    /// Lighter green used for the shine highlight on drips and droplets.
    private let highlight: Color = Color(red: 0.78, green: 1.0, blue: 0.58).opacity(0.75)

    // MARK: - Body

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                simulation.advance(to: context.date, bounds: size)
                drawSlime(in: ctx, size: size)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Private Helpers

    private func drawSlime(in context: GraphicsContext, size: CGSize) {
        let band = simulation.bandHeight
        let bodyShading = GraphicsContext.Shading.color(slimeColor)
        let highlightShading = GraphicsContext.Shading.color(highlight)

        // 1. Top ooze layer: a base rectangle from off-screen down to the
        //    band. Always at least this tall everywhere across the width.
        context.fill(
            Path(CGRect(x: -20, y: -60, width: size.width + 40, height: band + 60)),
            with: bodyShading
        )

        // 2. Lobes: filled circles whose top halves are hidden by the base
        //    rectangle above. The visible bottom halves form the irregular
        //    rounded bumps along the band's underside. Adjacent lobes overlap
        //    so they read as one continuous shape.
        for lobe in simulation.lobes {
            let rect = CGRect(
                x: lobe.x - lobe.depth,
                y: band - lobe.depth,
                width: lobe.depth * 2,
                height: lobe.depth * 2
            )
            context.fill(Path(ellipseIn: rect), with: bodyShading)
        }

        // 3. Drips: smooth teardrops attached under the band.
        for drip in simulation.drips {
            context.fill(dripPath(for: drip, band: band), with: bodyShading)
            // Shine highlight at the top-left of the bulb portion.
            drawDripHighlight(for: drip, band: band, in: context, shading: highlightShading)
        }

        // 4. Free-falling droplets — small teardrop pointing up so the rounded
        //    bottom leads the fall.
        for droplet in simulation.droplets {
            context.fill(droppingPath(for: droplet), with: bodyShading)
            drawDropletHighlight(for: droplet, in: context, shading: highlightShading)
        }
    }

    /// Builds the closed teardrop `Path` for a hanging drip — narrow at the
    /// top attachment, bulging to a rounded tip at the bottom. The bulb size
    /// grows with the drip's `progress` toward `maxLength` so detachment
    /// reads as impending.
    private func dripPath(for drip: SlimeDrip, band: CGFloat) -> Path {
        // Tuck the top into the band by a few px so the seam disappears.
        let topY = band - 6
        let bottomY = band + drip.length
        let topHalfWidth = drip.stemThickness / 2

        let progress = min(1, drip.length / drip.maxLength)
        let bulbRadius = drip.stemThickness * (0.55 + 0.75 * progress)
        let bulbCenterY = bottomY - bulbRadius

        // Cubic-Bezier circle approximation constant.
        let k: CGFloat = 0.5523

        var path = Path()
        path.move(to: CGPoint(x: drip.x - topHalfWidth, y: topY))

        // Left side: smooth taper from narrow top to wider bulb.
        path.addQuadCurve(
            to: CGPoint(x: drip.x - bulbRadius, y: bulbCenterY),
            control: CGPoint(
                x: drip.x - max(topHalfWidth, bulbRadius) - 3,
                y: (topY + bulbCenterY) / 2
            )
        )

        // Bottom half-circle around the tip via one cubic — ends back at the
        // bulb's right-middle.
        path.addCurve(
            to: CGPoint(x: drip.x + bulbRadius, y: bulbCenterY),
            control1: CGPoint(x: drip.x - bulbRadius, y: bulbCenterY + bulbRadius * k),
            control2: CGPoint(x: drip.x + bulbRadius, y: bulbCenterY + bulbRadius * k)
        )

        // Right side: mirror of the left taper back up to the top attachment.
        path.addQuadCurve(
            to: CGPoint(x: drip.x + topHalfWidth, y: topY),
            control: CGPoint(
                x: drip.x + max(topHalfWidth, bulbRadius) + 3,
                y: (topY + bulbCenterY) / 2
            )
        )

        path.closeSubpath()
        return path
    }

    /// Small wet-look highlight blob sitting on the upper-left of the drip's bulb.
    private func drawDripHighlight(for drip: SlimeDrip, band: CGFloat,
                                   in context: GraphicsContext, shading: GraphicsContext.Shading) {
        let progress = min(1, drip.length / drip.maxLength)
        let bulbRadius = drip.stemThickness * (0.55 + 0.75 * progress)
        let bulbCenterY = band + drip.length - bulbRadius
        let r = bulbRadius * 0.35
        let rect = CGRect(
            x: drip.x - bulbRadius * 0.55,
            y: bulbCenterY - bulbRadius * 0.55,
            width: r * 2,
            height: r * 2
        )
        context.fill(Path(ellipseIn: rect), with: shading)
    }

    /// Builds the closed "raindrop" `Path` for a free-falling droplet — narrow
    /// at the top, rounded bottom. Resembles slime stretching as it falls.
    private func droppingPath(for droplet: SlimeDroplet) -> Path {
        let r = droplet.radius
        let cx = droplet.position.x
        let cy = droplet.position.y
        // Stretch a little along the velocity direction (always down in practice),
        // so faster droplets read as more elongated.
        let stretch = max(1, min(1.6, droplet.velocity.dy / 800))
        let top = cy - r * stretch
        let bottom = cy + r
        let k: CGFloat = 0.5523

        var path = Path()
        // Pointed top.
        path.move(to: CGPoint(x: cx, y: top))
        // Right side: smoothly out to the widest point at the middle, then
        // around the rounded bottom and back up to the pointed top.
        path.addCurve(
            to: CGPoint(x: cx + r, y: cy),
            control1: CGPoint(x: cx + r * 0.55, y: top + (cy - top) * 0.55),
            control2: CGPoint(x: cx + r, y: cy - r * 0.3)
        )
        path.addCurve(
            to: CGPoint(x: cx - r, y: cy),
            control1: CGPoint(x: cx + r, y: bottom),
            control2: CGPoint(x: cx - r, y: bottom)
        )
        path.addCurve(
            to: CGPoint(x: cx, y: top),
            control1: CGPoint(x: cx - r, y: cy - r * 0.3),
            control2: CGPoint(x: cx - r * 0.55, y: top + (cy - top) * 0.55)
        )
        path.closeSubpath()
        _ = k
        return path
    }

    /// Wet-look highlight on the upper-left of a free-falling droplet.
    private func drawDropletHighlight(for droplet: SlimeDroplet,
                                      in context: GraphicsContext,
                                      shading: GraphicsContext.Shading) {
        let r = droplet.radius * 0.35
        let rect = CGRect(
            x: droplet.position.x - droplet.radius * 0.55,
            y: droplet.position.y - droplet.radius * 0.55,
            width: r * 2,
            height: r * 2
        )
        context.fill(Path(ellipseIn: rect), with: shading)
    }
}

#Preview {
    SlimeBorderView()
        .frame(width: 800, height: 500)
        .background(.black)
}
