//
//  PitPatTreadmillSample.swift
//  TestDrive
//

import Foundation

/// The typed contents of one PitPat treadmill state notification.
///
/// The machine reports metric units over the air regardless of what its own panel
/// is set to display, so every value here is metric and ``isImperialPanel`` only
/// describes the console.
struct PitPatTreadmillSample {

    /// The belt state reported in the status flags.
    enum Status: String {
        case countdown = "Counting down"
        case running = "Running"
        case paused = "Paused"
        case stopped = "Stopped"
    }

    /// The current belt state.
    let status: Status

    /// The speed the belt is actually running at, in km/h.
    let speedKilometresPerHour: Double

    /// The speed the belt has been commanded to reach, in km/h.
    let targetSpeedKilometresPerHour: Double

    /// The highest speed this machine will accept, in km/h.
    let maximumSpeedKilometresPerHour: Double

    /// Cumulative distance for the session, in kilometres.
    let distanceKilometres: Double

    /// Cumulative energy for the session, in kilocalories.
    let calories: UInt16

    /// Cumulative step count for the session.
    let steps: UInt32

    /// Elapsed session time in seconds, rounded down from the transmitted milliseconds.
    let elapsedSeconds: Int

    /// The firmware version byte.
    let firmwareVersion: UInt8

    /// Whether the machine's own console is displaying imperial units.
    ///
    /// Purely cosmetic: it does not change the units on the wire.
    let isImperialPanel: Bool

    /// The raw status-flags byte, kept for display alongside the decoded state.
    let statusFlags: UInt8

    // MARK: - Public Helpers

    /// The current belt speed converted to miles per hour, which is what the
    /// SupeRun console shows in its default configuration.
    var speedMilesPerHour: Double {
        speedKilometresPerHour / PitPatTreadmillDataDecoder.kilometresPerMile
    }

    /// The session distance converted to miles.
    var distanceMiles: Double {
        distanceKilometres / PitPatTreadmillDataDecoder.kilometresPerMile
    }
}
