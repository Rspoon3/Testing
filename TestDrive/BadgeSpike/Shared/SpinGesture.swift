//
//  SpinGesture.swift
//  TestDrive
//

import SwiftUI

/// Tracks a badge's spin angle from a drag, with release momentum.
///
/// Extracted because three of the five tabs need identical spin feel — comparing
/// rendering techniques is only meaningful if the interaction is held constant.
@Observable
@MainActor
final class SpinGesture {
    /// The current yaw, in degrees. Unbounded, so it can wind past 360.
    var angle: Double = CaptureOverrides.angle ?? 0

    /// Whether a finger is currently down, which suspends the idle drift.
    private(set) var isDragging = false

    private var angleAtDragStart: Double = 0

    // MARK: - Public Helpers

    /// Applies a drag translation.
    /// - Parameter translation: The gesture's horizontal travel, in points.
    func drag(translation: CGFloat) {
        if !isDragging {
            isDragging = true
            angleAtDragStart = angle
        }
        // 0.6°/pt: a full spin takes a ~600pt swipe, so a comfortable thumb flick
        // turns the badge about three-quarters of the way round.
        angle = angleAtDragStart + translation * 0.6
    }

    /// Ends the drag, carrying the fling's momentum into a decaying spin.
    /// - Parameter predictedTranslation: The gesture's predicted end translation,
    ///   which SwiftUI derives from release velocity.
    func endDrag(predictedTranslation: CGFloat) {
        isDragging = false
        let momentum = (predictedTranslation - (angle - angleAtDragStart) / 0.6) * 0.6
        withAnimation(.interpolatingSpring(stiffness: 8, damping: 4.2)) {
            angle += momentum
        }
    }

    /// Advances the idle drift, used when no finger is down.
    ///
    /// The simulator has no gyroscope, so without this the badge is motionless
    /// unless touched and there is nothing to evaluate.
    /// - Parameter degrees: How far to turn this frame.
    func drift(degrees: Double) {
        guard !isDragging else { return }
        angle += degrees
    }
}
