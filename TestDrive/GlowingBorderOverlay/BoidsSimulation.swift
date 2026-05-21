//
//  BoidsSimulation.swift
//  TestDrive
//

import CoreGraphics
import Foundation

/// Drives a flock of ``Boid``s using the three classical Reynolds steering rules
/// (separation, alignment, cohesion) plus an optional seek toward a user-supplied
/// target point — e.g. the user's finger.
///
/// The simulation is intentionally a plain reference type rather than `@Observable`:
/// re-renders are driven by `TimelineView(.animation)`, so reactivity would only
/// add overhead. Call ``advance(to:bounds:)`` once per frame from the view.
@MainActor
final class BoidsSimulation {

    /// Current snapshot of all boids in the flock.
    private(set) var boids: [Boid] = []

    /// The point boids seek toward, or `nil` to let them flock freely.
    var target: CGPoint?

    // Tunable parameters. Defaults give a calm, screen-filling flock at 60Hz.
    var separationRadius: CGFloat = 40
    var neighborRadius: CGFloat = 70
    var maxSpeed: CGFloat = 220
    var maxForce: CGFloat = 600
    var separationWeight: CGFloat = 2.0
    var alignmentWeight: CGFloat = 1.0
    var cohesionWeight: CGFloat = 1.0
    var targetWeight: CGFloat = 1.8

    /// Radius at which boids switch from chasing the target to circling it.
    var orbitRadius: CGFloat = 70

    /// How far around the orbit each boid aims ahead of itself, in radians.
    /// Sign controls rotation direction — positive is clockwise in screen coords.
    var orbitLeadAngle: CGFloat = 0.55

    private var lastDate: Date?

    // MARK: - Initializer

    /// Creates a simulation with `count` boids scattered through `bounds`.
    init(count: Int = 80, bounds: CGSize = CGSize(width: 400, height: 400)) {
        boids = (0..<count).map { _ in
            Boid(
                position: CGPoint(
                    x: .random(in: 0...bounds.width),
                    y: .random(in: 0...bounds.height)
                ),
                velocity: CGVector(
                    dx: .random(in: -60...60),
                    dy: .random(in: -60...60)
                )
            )
        }
    }

    // MARK: - Public Helpers

    /// Advances the simulation to the supplied date.
    ///
    /// Tracks the previous call's date so it can compute a real `dt`. Large gaps
    /// (background → foreground, etc.) are clamped to avoid a single huge step.
    /// - Parameters:
    ///   - date: The current frame time, typically from `TimelineView`.
    ///   - bounds: The viewport boids wrap around within.
    func advance(to date: Date, bounds: CGSize) {
        defer { lastDate = date }
        guard let lastDate else { return }
        let dt = min(date.timeIntervalSince(lastDate), 0.05)
        guard dt > 0 else { return }
        step(dt: dt, bounds: bounds)
    }

    // MARK: - Private Helpers

    /// Integrates one fixed-`dt` step of the flock using the classical Reynolds rules.
    private func step(dt: TimeInterval, bounds: CGSize) {
        let snapshot = boids
        let dt = CGFloat(dt)

        for i in boids.indices {
            let self_ = snapshot[i]
            var separation = CGVector.zero
            var alignmentSum = CGVector.zero
            var alignmentCount = 0
            var cohesionSum = CGPoint.zero
            var cohesionCount = 0

            for j in snapshot.indices where j != i {
                let other = snapshot[j]
                let dx = self_.position.x - other.position.x
                let dy = self_.position.y - other.position.y
                let distSq = dx * dx + dy * dy
                guard distSq > 0 else { continue }
                let dist = sqrt(distSq)

                if dist < separationRadius {
                    // Weight by 1/dist so very close neighbors push hardest.
                    separation.dx += dx / dist
                    separation.dy += dy / dist
                }
                if dist < neighborRadius {
                    alignmentSum.dx += other.velocity.dx
                    alignmentSum.dy += other.velocity.dy
                    alignmentCount += 1
                    cohesionSum.x += other.position.x
                    cohesionSum.y += other.position.y
                    cohesionCount += 1
                }
            }

            var acceleration = CGVector.zero

            if separation.dx != 0 || separation.dy != 0 {
                acceleration += steer(toward: separation, from: self_) * separationWeight
            }
            if alignmentCount > 0 {
                let avg = CGVector(
                    dx: alignmentSum.dx / CGFloat(alignmentCount),
                    dy: alignmentSum.dy / CGFloat(alignmentCount)
                )
                acceleration += steer(toward: avg, from: self_) * alignmentWeight
            }
            if cohesionCount > 0 {
                let center = CGPoint(
                    x: cohesionSum.x / CGFloat(cohesionCount),
                    y: cohesionSum.y / CGFloat(cohesionCount)
                )
                acceleration += seek(from: self_, toward: center) * cohesionWeight
            }
            if let target {
                acceleration += seek(from: self_, toward: orbitAim(for: self_, target: target)) * targetWeight
            }

            var newVelocity = CGVector(
                dx: self_.velocity.dx + acceleration.dx * dt,
                dy: self_.velocity.dy + acceleration.dy * dt
            )
            newVelocity = limit(newVelocity, max: maxSpeed)

            var newPosition = CGPoint(
                x: self_.position.x + newVelocity.dx * dt,
                y: self_.position.y + newVelocity.dy * dt
            )
            // Wrap around the viewport edges so the flock can drift indefinitely.
            if bounds.width > 0 {
                if newPosition.x < 0 { newPosition.x += bounds.width }
                if newPosition.x > bounds.width { newPosition.x -= bounds.width }
            }
            if bounds.height > 0 {
                if newPosition.y < 0 { newPosition.y += bounds.height }
                if newPosition.y > bounds.height { newPosition.y -= bounds.height }
            }

            boids[i].velocity = newVelocity
            boids[i].position = newPosition
        }
    }

    /// Returns the point a boid should aim at: the raw target while far away,
    /// or a point a fixed angle ahead along the orbit circle once it's close.
    /// This produces a real-bird-style circling band instead of a tight clump.
    private func orbitAim(for boid: Boid, target: CGPoint) -> CGPoint {
        let dx = boid.position.x - target.x
        let dy = boid.position.y - target.y
        let dist = sqrt(dx * dx + dy * dy)
        guard dist < orbitRadius * 1.6, dist > 0 else { return target }
        let currentAngle = atan2(dy, dx)
        let aheadAngle = currentAngle + orbitLeadAngle
        return CGPoint(
            x: target.x + orbitRadius * cos(aheadAngle),
            y: target.y + orbitRadius * sin(aheadAngle)
        )
    }

    /// Returns a clamped steering force pushing `boid` toward `target`.
    private func seek(from boid: Boid, toward target: CGPoint) -> CGVector {
        let desired = CGVector(dx: target.x - boid.position.x, dy: target.y - boid.position.y)
        return steer(toward: desired, from: boid)
    }

    /// Converts a desired direction into a Reynolds-style steering force:
    /// scale to `maxSpeed`, subtract current velocity, clamp to `maxForce`.
    private func steer(toward desired: CGVector, from boid: Boid) -> CGVector {
        let mag = sqrt(desired.dx * desired.dx + desired.dy * desired.dy)
        guard mag > 0 else { return .zero }
        let scaled = CGVector(
            dx: desired.dx / mag * maxSpeed,
            dy: desired.dy / mag * maxSpeed
        )
        let steer = CGVector(dx: scaled.dx - boid.velocity.dx, dy: scaled.dy - boid.velocity.dy)
        return limit(steer, max: maxForce)
    }

    /// Returns `vector` truncated to magnitude `max`.
    private func limit(_ vector: CGVector, max: CGFloat) -> CGVector {
        let mag = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
        guard mag > max else { return vector }
        return CGVector(dx: vector.dx * max / mag, dy: vector.dy * max / mag)
    }
}

// MARK: - CGVector arithmetic

private extension CGVector {
    static func += (lhs: inout CGVector, rhs: CGVector) {
        lhs.dx += rhs.dx
        lhs.dy += rhs.dy
    }

    static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }
}
