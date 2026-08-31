//
//  BadgeMotion.swift
//  TestDrive
//

import CoreMotion
import Observation
import SwiftUI

/// Publishes device attitude as a normalized tilt, for driving highlights.
///
/// The point of comparison across tabs: a badge that only moves when touched
/// feels like a picture, and a badge whose highlight slides as the phone tilts
/// feels like an object. Every tab reads the same two numbers from here.
///
/// **Simulator note:** there is no gyroscope, so `isAvailable` is `false` and
/// `tilt` stays at zero. Tabs fall back to a slow automatic drift so the effect
/// is still visible without a device.
@Observable
@MainActor
final class BadgeMotion {
    /// Roll and pitch, each roughly clamped to -1...1.
    private(set) var tilt: SIMD2<Double> = .zero

    /// Whether the device can report attitude at all.
    var isAvailable: Bool {
        manager.isDeviceMotionAvailable
    }

    @ObservationIgnored private let manager = CMMotionManager()

    // MARK: - Initializer

    /// Creates a stopped motion source.
    init() {
        manager.deviceMotionUpdateInterval = 1 / 60
    }

    // MARK: - Public Helpers

    /// Begins attitude updates.
    ///
    /// A no-op when Reduce Motion or Low Power Mode is on: the idle wobble is
    /// exactly the kind of unrequested movement Reduce Motion exists to suppress,
    /// and a 60 Hz sensor stream is a real battery cost to volunteer.
    /// - Parameter reduceMotion: The environment's Reduce Motion setting.
    func start(reduceMotion: Bool) {
        guard
            manager.isDeviceMotionAvailable,
            !manager.isDeviceMotionActive,
            !reduceMotion,
            !ProcessInfo.processInfo.isLowPowerModeEnabled
        else { return }

        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            // Roll and pitch in radians, scaled so a comfortable wrist range covers
            // most of -1...1. Divided by ~50° rather than 90° because nobody tilts a
            // phone to the limit while looking at it.
            let scale = Double.pi / 3.5
            tilt = SIMD2(
                (motion.attitude.roll / scale).clampedToUnit,
                (motion.attitude.pitch / scale).clampedToUnit
            )
        }
    }

    /// Ends attitude updates. Call from `onDisappear`.
    func stop() {
        manager.stopDeviceMotionUpdates()
        tilt = .zero
    }
}

private extension Double {
    /// Clamps to -1...1.
    var clampedToUnit: Double {
        min(max(self, -1), 1)
    }
}
