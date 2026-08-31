//
//  IdleDrift.swift
//  TestDrive
//

import SwiftUI

/// Slowly turns a badge while nothing is touching it.
///
/// Exists for the simulator, which has no gyroscope: without a drift the badge is
/// motionless unless dragged, and three of these five approaches are mostly about
/// how light moves across a surface. Driven by a clock task rather than a
/// `TimelineView`, so the angle is mutated from an async context instead of during
/// a view update.
struct IdleDriftModifier: ViewModifier {
    private let spin: SpinGesture
    private let isEnabled: Bool
    private let degreesPerSecond: Double

    // MARK: - Initializer

    /// Creates the modifier.
    /// - Parameters:
    ///   - spin: The spin state to advance.
    ///   - isEnabled: Whether to drift at all.
    ///   - degreesPerSecond: How fast to turn.
    init(spin: SpinGesture, isEnabled: Bool, degreesPerSecond: Double) {
        self.spin = spin
        self.isEnabled = isEnabled
        self.degreesPerSecond = degreesPerSecond
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content.task(id: isEnabled) {
            guard isEnabled else { return }

            let frameDuration = Duration.seconds(1.0 / 60.0)
            let step = degreesPerSecond / 60.0

            // Cancelled automatically when the view disappears or `isEnabled` flips,
            // which is what stops it from outliving the tab.
            while !Task.isCancelled {
                try? await Task.sleep(for: frameDuration)
                spin.drift(degrees: step)
            }
        }
    }
}

extension View {

    // MARK: - Public Helpers

    /// Slowly turns the badge while it is not being dragged.
    /// - Parameters:
    ///   - spin: The spin state to advance.
    ///   - isEnabled: Whether to drift.
    ///   - degreesPerSecond: How fast to turn. Defaults to a slow show-turn.
    /// - Returns: The view, drifting.
    func idleDrift(
        spin: SpinGesture,
        isEnabled: Bool,
        degreesPerSecond: Double = 22
    ) -> some View {
        modifier(
            IdleDriftModifier(
                spin: spin,
                isEnabled: isEnabled,
                degreesPerSecond: degreesPerSecond
            )
        )
    }
}
