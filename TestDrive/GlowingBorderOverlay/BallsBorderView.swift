//
//  BallsBorderView.swift
//  TestDrive
//

import SwiftUI

/// A bunch of colored balls dropping from above and bouncing off the floor
/// and the side walls of the screen.
///
/// Uses `TimelineView(.animation)` to drive a `Canvas`, with the simulation
/// stepping inside the draw closure so positions advance once per frame.
/// Each ball is rendered as a circle plus a small white highlight for a
/// crude pseudo-3D look.
struct BallsBorderView: View {
    @State private var simulation = BallsSimulation()

    // MARK: - Body

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                simulation.advance(to: context.date, bounds: size)
                for ball in simulation.balls {
                    draw(ball, in: ctx)
                }
            }
        }
        .background(.clear)
    }

    // MARK: - Private Helpers

    private func draw(_ ball: Ball, in context: GraphicsContext) {
        let bodyRect = CGRect(
            x: ball.position.x - ball.radius,
            y: ball.position.y - ball.radius,
            width: ball.radius * 2,
            height: ball.radius * 2
        )
        context.fill(Path(ellipseIn: bodyRect), with: .color(ball.color))

        // Inner highlight near the top-left for a soft 3D shading.
        let highlightRadius = ball.radius * 0.35
        let highlightRect = CGRect(
            x: ball.position.x - ball.radius * 0.45,
            y: ball.position.y - ball.radius * 0.45,
            width: highlightRadius * 2,
            height: highlightRadius * 2
        )
        context.fill(Path(ellipseIn: highlightRect), with: .color(.white.opacity(0.35)))
    }
}

#Preview {
    BallsBorderView()
        .frame(width: 800, height: 500)
        .background(.black)
}
