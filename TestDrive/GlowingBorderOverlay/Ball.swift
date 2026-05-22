//
//  Ball.swift
//  TestDrive
//

import CoreGraphics
import Foundation
import SwiftUI

/// A single bouncing ball in the gravity simulation.
struct Ball: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGVector
    let radius: CGFloat
    let color: Color

    init(id: UUID = UUID(), position: CGPoint, velocity: CGVector, radius: CGFloat, color: Color) {
        self.id = id
        self.position = position
        self.velocity = velocity
        self.radius = radius
        self.color = color
    }
}
