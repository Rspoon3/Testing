//
//  Boid.swift
//  TestDrive
//

import CoreGraphics
import Foundation

/// A single agent in a Reynolds-style flocking simulation.
///
/// Boids store their state in screen-space points (position) and points-per-second
/// velocity. The simulation owns the integration step — see ``BoidsSimulation``.
struct Boid: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGVector

    init(id: UUID = UUID(), position: CGPoint, velocity: CGVector) {
        self.id = id
        self.position = position
        self.velocity = velocity
    }
}
