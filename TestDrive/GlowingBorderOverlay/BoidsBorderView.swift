//
//  BoidsBorderView.swift
//  TestDrive
//

import AppKit
import SwiftUI

/// A flock of small birds that swarm across the desktop overlay and chase the
/// user's cursor.
///
/// Renders via `TimelineView(.animation)` + `Canvas` so the simulation can step at
/// the display's refresh rate. Because the host window is click-through, no local
/// pointer events arrive — instead we poll `NSEvent.mouseLocation` each frame and
/// convert it into the canvas' top-down coordinate space.
struct BoidsBorderView: View {
    let color: Color
    let screen: NSScreen?

    @State private var simulation = BoidsSimulation()

    // MARK: - Body

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                simulation.target = cursorPosition(in: size)
                simulation.advance(to: context.date, bounds: size)
                drawBoids(in: ctx)
            }
        }
        .background(.clear)
    }

    // MARK: - Private Helpers

    /// Converts the global cursor location into top-down canvas coords, or returns
    /// `nil` when the cursor is on a different screen (so this screen's boids drift
    /// freely instead of chasing an off-screen target).
    private func cursorPosition(in size: CGSize) -> CGPoint? {
        guard let screen else { return nil }
        let global = NSEvent.mouseLocation
        guard screen.frame.contains(global) else { return nil }
        let localX = global.x - screen.frame.minX
        let localY = global.y - screen.frame.minY
        return CGPoint(x: localX, y: size.height - localY)
    }

    /// Renders every boid as a small triangle pointing along its velocity.
    private func drawBoids(in context: GraphicsContext) {
        let bodyShading = GraphicsContext.Shading.color(color)
        let trailShading = GraphicsContext.Shading.color(color.opacity(0.35))
        for boid in simulation.boids {
            let angle = atan2(boid.velocity.dy, boid.velocity.dx)
            context.drawLayer { layer in
                layer.translateBy(x: boid.position.x, y: boid.position.y)
                layer.rotate(by: .radians(angle))
                layer.fill(boidShape, with: bodyShading)
                layer.fill(trailShape, with: trailShading)
            }
        }
    }

    /// A small forward-pointing triangle drawn at the boid's origin.
    private var boidShape: Path {
        var path = Path()
        path.move(to: CGPoint(x: 9, y: 0))
        path.addLine(to: CGPoint(x: -5, y: -4))
        path.addLine(to: CGPoint(x: -5, y: 4))
        path.closeSubpath()
        return path
    }

    /// A faint tail behind the boid, used as a motion hint.
    private var trailShape: Path {
        var path = Path()
        path.move(to: CGPoint(x: -5, y: -2))
        path.addLine(to: CGPoint(x: -14, y: 0))
        path.addLine(to: CGPoint(x: -5, y: 2))
        path.closeSubpath()
        return path
    }
}

#Preview {
    BoidsBorderView(color: .red, screen: nil)
        .frame(width: 800, height: 500)
        .background(.black)
}
