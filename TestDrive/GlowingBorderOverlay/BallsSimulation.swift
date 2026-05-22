//
//  BallsSimulation.swift
//  TestDrive
//

import CoreGraphics
import Foundation
import SwiftUI

/// Drives a swarm of ``Ball``s that drop from above the screen, fall under
/// gravity, and bounce off the floor and side walls with light damping.
///
/// Spawns new balls steadily up to a cap so the screen stays lively. Like
/// the boids sim, this is a plain class — re-renders are driven by
/// `TimelineView(.animation)`, so reactivity would just add overhead.
@MainActor
final class BallsSimulation {

    /// Current snapshot of every active ball.
    private(set) var balls: [Ball] = []

    /// Pixels per second² of downward acceleration.
    var gravity: CGFloat = 1600

    /// Velocity multiplier each time a ball touches the floor. Lower = bouncier loss.
    var floorBounce: CGFloat = 0.78

    /// Velocity multiplier each time a ball touches a wall.
    var wallBounce: CGFloat = 0.85

    /// Horizontal friction applied while a ball is in contact with the floor.
    var floorFriction: CGFloat = 0.985

    /// Velocity multiplier on ball-to-ball collisions. Lower = more energy lost.
    var ballRestitution: CGFloat = 0.85

    /// Upper bound on the number of balls in the simulation at once.
    var maxBalls = 100

    /// How many balls to spawn per second once the initial drop is in flight.
    var spawnRate: Double = 8

    private var lastDate: Date?
    private var spawnAccumulator: Double = 0

    /// Palette balls cycle through. Multi-color by default — looks more like a ball pit.
    private let palette: [Color] = [
        .red, .orange, .yellow, .green, .mint, .blue, .indigo, .purple, .pink
    ]

    // MARK: - Public Helpers

    /// Advances the simulation to the supplied date and lazily seeds the
    /// initial drop the first time it's called for a given bounds.
    func advance(to date: Date, bounds: CGSize) {
        defer { lastDate = date }
        guard bounds.width > 0, bounds.height > 0 else { return }

        guard let lastDate else {
            // First tick — seed a batch of balls above the screen so the first
            // drop is satisfyingly chunky instead of trickling in one at a time.
            seedInitialDrop(into: bounds)
            return
        }

        let dt = CGFloat(min(date.timeIntervalSince(lastDate), 0.05))
        guard dt > 0 else { return }
        step(dt: dt, bounds: bounds)
        spawnIfNeeded(dt: Double(dt), bounds: bounds)
    }

    // MARK: - Private Helpers

    private func seedInitialDrop(into bounds: CGSize) {
        for _ in 0..<32 {
            balls.append(makeBall(in: bounds))
        }
    }

    private func step(dt: CGFloat, bounds: CGSize) {
        // 1. Integrate gravity + motion for every ball.
        for i in balls.indices {
            balls[i].velocity.dy += gravity * dt
            balls[i].position.x += balls[i].velocity.dx * dt
            balls[i].position.y += balls[i].velocity.dy * dt
        }

        // 2. Resolve ball-to-ball collisions.
        resolveBallCollisions()

        // 3. Clamp against the floor and side walls — applied last so a
        //    collision impulse can't punch a ball through a wall.
        for i in balls.indices {
            var ball = balls[i]

            if ball.position.y + ball.radius > bounds.height {
                ball.position.y = bounds.height - ball.radius
                if ball.velocity.dy > 0 {
                    ball.velocity.dy = -ball.velocity.dy * floorBounce
                }
                ball.velocity.dx *= floorFriction
            }
            if ball.position.x - ball.radius < 0 {
                ball.position.x = ball.radius
                if ball.velocity.dx < 0 {
                    ball.velocity.dx = -ball.velocity.dx * wallBounce
                }
            }
            if ball.position.x + ball.radius > bounds.width {
                ball.position.x = bounds.width - ball.radius
                if ball.velocity.dx > 0 {
                    ball.velocity.dx = -ball.velocity.dx * wallBounce
                }
            }

            balls[i] = ball
        }
    }

    /// O(n²) pairwise circle collision resolution. Pushes overlapping balls
    /// apart and exchanges velocity along the contact normal using an impulse
    /// scaled by inverse mass — mass is `radius²`, so bigger balls bully smaller ones.
    private func resolveBallCollisions() {
        let count = balls.count
        guard count > 1 else { return }
        for i in 0..<(count - 1) {
            for j in (i + 1)..<count {
                var a = balls[i]
                var b = balls[j]
                let dx = b.position.x - a.position.x
                let dy = b.position.y - a.position.y
                let distSq = dx * dx + dy * dy
                let minDist = a.radius + b.radius
                guard distSq < minDist * minDist, distSq > 0 else { continue }
                let dist = sqrt(distSq)
                let nx = dx / dist
                let ny = dy / dist

                let massA = a.radius * a.radius
                let massB = b.radius * b.radius
                let totalMass = massA + massB

                // Positional correction — split the overlap by inverse mass
                // so a heavy ball barely moves and a tiny ball pops out of the way.
                let overlap = minDist - dist
                let pushA = overlap * massB / totalMass
                let pushB = overlap * massA / totalMass
                a.position.x -= nx * pushA
                a.position.y -= ny * pushA
                b.position.x += nx * pushB
                b.position.y += ny * pushB

                // Impulse-based velocity update along the contact normal.
                // Only fire when the balls are actually moving toward each other.
                let vrelN = (b.velocity.dx - a.velocity.dx) * nx
                              + (b.velocity.dy - a.velocity.dy) * ny
                if vrelN < 0 {
                    let impulse = -(1 + ballRestitution) * vrelN
                                  / (1 / massA + 1 / massB)
                    a.velocity.dx -= impulse * nx / massA
                    a.velocity.dy -= impulse * ny / massA
                    b.velocity.dx += impulse * nx / massB
                    b.velocity.dy += impulse * ny / massB
                }

                balls[i] = a
                balls[j] = b
            }
        }
    }

    /// Drips new balls in at `spawnRate`/sec up to `maxBalls`.
    private func spawnIfNeeded(dt: Double, bounds: CGSize) {
        guard balls.count < maxBalls else { return }
        spawnAccumulator += dt * spawnRate
        while spawnAccumulator >= 1, balls.count < maxBalls {
            spawnAccumulator -= 1
            balls.append(makeBall(in: bounds))
        }
    }

    private func makeBall(in bounds: CGSize) -> Ball {
        let radius = CGFloat.random(in: 14...34)
        return Ball(
            position: CGPoint(
                x: .random(in: radius...max(radius, bounds.width - radius)),
                y: -radius - .random(in: 0...80)
            ),
            velocity: CGVector(
                dx: .random(in: -120...120),
                dy: .random(in: 0...80)
            ),
            radius: radius,
            color: palette.randomElement() ?? .red
        )
    }
}
