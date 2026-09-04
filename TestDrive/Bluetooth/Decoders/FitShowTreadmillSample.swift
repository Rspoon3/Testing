//
//  FitShowTreadmillSample.swift
//  TestDrive
//

import Foundation

/// The typed contents of one FitShow running-status frame.
///
/// Speed and distance are deliberately left as the raw tenths the machine sent.
/// The FitShow protocol carries no unit marker in the status frame, and the
/// reference implementations disagree about whether the value is metric or
/// imperial — so the decoder reports the number the machine sent and shows both
/// readings rather than silently picking one. Walk at a speed the console displays
/// and whichever reading matches is the answer for that firmware.
struct FitShowTreadmillSample {

    /// The belt state reported in the frame's parameter byte.
    enum Status: UInt8 {
        case normal = 0
        case ended = 1
        case starting = 2
        case running = 3
        case stopped = 4
        case error = 5
        case safetyKeyRemoved = 6
        case learning = 7
        case paused = 10

        /// A readable name for the state.
        var name: String {
            switch self {
            case .normal: "Idle"
            case .ended: "Session ended"
            case .starting: "Starting"
            case .running: "Running"
            case .stopped: "Stopped"
            case .error: "Error"
            case .safetyKeyRemoved: "Safety key removed"
            case .learning: "Self-test"
            case .paused: "Paused"
            }
        }
    }

    /// The belt state.
    let status: Status

    /// Belt speed in tenths of a unit per hour, exactly as transmitted.
    let speedTenths: UInt8

    /// Incline as a signed percentage, or level, depending on the machine.
    let incline: Int8

    /// Elapsed session time in seconds.
    let elapsedSeconds: UInt16

    /// Cumulative distance in tenths of a unit, exactly as transmitted.
    let distanceTenths: UInt16

    /// Cumulative energy in kilocalories.
    let calories: UInt16

    /// Cumulative step count.
    let steps: UInt16

    /// Heart rate in beats per minute, `0` when no strap is detected.
    let heartRate: UInt8

    // MARK: - Public Helpers

    /// The transmitted speed as a decimal, in whichever unit the firmware uses.
    var speed: Double { Double(speedTenths) / 10 }

    /// The transmitted distance as a decimal, in whichever unit the firmware uses.
    var distance: Double { Double(distanceTenths) / 10 }

    /// Whether a heart rate was reported at all.
    var hasHeartRate: Bool { heartRate > 0 }
}
