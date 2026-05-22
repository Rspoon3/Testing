//
//  SlimeSimulation.swift
//  TestDrive
//

import CoreGraphics
import Foundation

/// One slime stalactite hanging from the top band. Grows over time until it
/// reaches `maxLength`, at which point the bottom bulb detaches as a
/// ``SlimeDroplet`` and the drip resets to a small starting length.
struct SlimeDrip {
    /// Horizontal position (px from left edge of the canvas).
    var x: CGFloat
    /// Current length of the stem, in pixels from the bottom of the top band.
    var length: CGFloat
    /// Length at which the bulb breaks off and a droplet spawns.
    let maxLength: CGFloat
    /// Stem growth rate (pixels/second).
    let growthRate: CGFloat
    /// Width of the stem at its top attachment point, in pixels.
    let stemThickness: CGFloat
}

/// A free-falling globule of slime. Generation 0 droplets are the originals
/// that fall from drips; when they hit the floor they're replaced with a
/// handful of generation-1 splash bits that fly outward.
struct SlimeDroplet: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    let radius: CGFloat
    /// `0` for the original drop, `1` for splash bits.
    let generation: Int
}

/// A static circular blob hanging from the underside of the top ooze layer.
/// Drawn on top of the base band so its lower half forms one of the rounded
/// "lobes" in the goo's bottom edge. Generated once per canvas width.
struct SlimeLobe {
    let x: CGFloat
    /// How far the visible part of the lobe sags below the band — the bottom
    /// half of a circle of this radius.
    let depth: CGFloat
}

/// Drives the dripping-goo simulation: a base ooze layer with rounded lobes,
/// a row of stalactites that stretch downward at independent rates, and
/// detached droplets that fall under gravity.
@MainActor
final class SlimeSimulation {

    /// Live drips currently hanging from the top.
    private(set) var drips: [SlimeDrip] = []

    /// Free-falling droplets that have detached from drips.
    private(set) var droplets: [SlimeDroplet] = []

    /// Static circular lobes drooping from the underside of the ooze layer.
    /// Generated once when the canvas size is first known.
    private(set) var lobes: [SlimeLobe] = []

    /// Height of the always-on top "ooze" band.
    let bandHeight: CGFloat = 28

    /// Constant goal for live drips on screen.
    var maxDrips = 9

    /// Pixels per second² of gravity applied to detached droplets.
    var gravity: CGFloat = 1200

    /// Minimum downward speed (px/sec) at which a gen-0 droplet's impact
    /// triggers a splash. Slower hits are just absorbed (silently culled).
    var splashThreshold: CGFloat = 200

    private var lastDate: Date?
    private var lobesGeneratedForWidth: CGFloat = 0

    // MARK: - Public Helpers

    /// Advances the simulation to `date`, seeding the initial drips the first
    /// time it's called for a real-sized canvas.
    func advance(to date: Date, bounds: CGSize) {
        defer { lastDate = date }
        guard bounds.width > 0, bounds.height > 0 else { return }
        if abs(bounds.width - lobesGeneratedForWidth) > 5 {
            lobes = generateLobes(width: bounds.width)
            lobesGeneratedForWidth = bounds.width
        }
        guard let lastDate else {
            seedDrips(in: bounds)
            return
        }
        let dt = CGFloat(min(date.timeIntervalSince(lastDate), 0.05))
        guard dt > 0 else { return }
        step(dt: dt, bounds: bounds)
    }

    // MARK: - Private Helpers

    private func seedDrips(in bounds: CGSize) {
        for _ in 0..<maxDrips {
            drips.append(makeDrip(in: bounds))
        }
    }

    private func step(dt: CGFloat, bounds: CGSize) {
        // Grow each drip; when it hits `maxLength`, pinch off a droplet and reset.
        for i in drips.indices {
            drips[i].length += drips[i].growthRate * dt
            if drips[i].length >= drips[i].maxLength {
                let bulbRadius = drips[i].stemThickness * 1.25
                droplets.append(SlimeDroplet(
                    position: CGPoint(x: drips[i].x, y: bandHeight + drips[i].length),
                    velocity: CGVector(dx: 0, dy: 60),
                    radius: bulbRadius,
                    generation: 0
                ))
                drips[i].length = .random(in: 4...18)
            }
        }

        // Integrate gravity + motion for every droplet.
        for i in droplets.indices {
            droplets[i].velocity.dy += gravity * dt
            droplets[i].position.x += droplets[i].velocity.dx * dt
            droplets[i].position.y += droplets[i].velocity.dy * dt
        }

        // Splash any gen-0 droplet that just touched the floor into a
        // handful of smaller bits that fly outward.
        var splashedIDs: Set<UUID> = []
        var newBits: [SlimeDroplet] = []
        for droplet in droplets {
            let dropletBottom = droplet.position.y + droplet.radius
            guard dropletBottom >= bounds.height else { continue }
            guard droplet.generation == 0, droplet.velocity.dy >= splashThreshold else { continue }
            splashedIDs.insert(droplet.id)
            newBits.append(contentsOf: makeSplashBits(at: droplet.position,
                                                      from: droplet.radius,
                                                      floorY: bounds.height))
        }
        droplets.removeAll { splashedIDs.contains($0.id) }
        droplets.append(contentsOf: newBits)

        // Cull anything below the floor — catches splash bits on their way
        // back down as well as anything that arrived too slowly to splash.
        droplets.removeAll { $0.position.y - $0.radius > bounds.height }

        // Replenish drips so the line at the top stays populated.
        while drips.count < maxDrips {
            drips.append(makeDrip(in: bounds))
        }
    }

    /// Builds 5–10 splash bits at the impact point with outward + upward
    /// velocities. Each is generation 1 so it can never re-splash.
    private func makeSplashBits(at impact: CGPoint, from radius: CGFloat, floorY: CGFloat) -> [SlimeDroplet] {
        let count = Int.random(in: 5...10)
        return (0..<count).map { _ in
            let bitRadius = radius * CGFloat.random(in: 0.28...0.55)
            // Upper half-plane angle (0.15π → 0.85π) — sin is always positive
            // so flipping sign gives a definitively-upward dy in our y-down coords.
            let angle = CGFloat.random(in: 0.15 * .pi ... 0.85 * .pi)
            let speed = CGFloat.random(in: 150...320)
            return SlimeDroplet(
                position: CGPoint(x: impact.x, y: floorY - bitRadius - 2),
                velocity: CGVector(dx: cos(angle) * speed, dy: -sin(angle) * speed),
                radius: bitRadius,
                generation: 1
            )
        }
    }

    private func makeDrip(in bounds: CGSize) -> SlimeDrip {
        SlimeDrip(
            x: .random(in: 20...max(20, bounds.width - 20)),
            length: .random(in: 4...20),
            maxLength: .random(in: 110...280),
            growthRate: .random(in: 24...68),
            stemThickness: .random(in: 8...18)
        )
    }

    /// Generates a row of overlapping circular lobes across the canvas width.
    /// Spacing is roughly fixed but each lobe gets a random x jitter and a
    /// random depth, so adjacent lobes merge into the irregular blob shapes
    /// you see in dripping-goo references.
    private func generateLobes(width: CGFloat) -> [SlimeLobe] {
        var result: [SlimeLobe] = []
        let spacing: CGFloat = 64
        var x: CGFloat = -20
        while x < width + 30 {
            result.append(SlimeLobe(
                x: x + CGFloat.random(in: -20...20),
                depth: CGFloat.random(in: 10...34)
            ))
            x += spacing
        }
        return result
    }
}
