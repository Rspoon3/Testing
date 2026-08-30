//
//  StepRateTracker.swift
//  TestDrive
//

import Foundation

/// Derives a live steps-per-minute figure from successive step-count readings.
///
/// The LiXuan controller never populates the FTMS Average Step Rate field and uses
/// the Step Per Minute field to carry its own SPEED level instead, so the machine's
/// console SPM value has no counterpart anywhere in the packet. The only way to
/// recover it is to differentiate the cumulative step count over time, which is what
/// this does.
///
/// Samples older than ``windowDuration`` are discarded so the figure tracks the
/// current effort rather than the session average, matching how the console's SPM
/// readout decays once you stop climbing.
struct StepRateTracker {

    /// How far back samples are kept when computing the rate.
    ///
    /// The machine notifies roughly once a second, so six seconds is enough history
    /// to smooth out the jitter between packets while still reacting within a couple
    /// of seconds when the climber changes speed.
    static let windowDuration: TimeInterval = 6

    /// The shortest span that will produce a rate. Below this the figure is too noisy
    /// to be meaningful, given the machine notifies roughly once a second.
    static let minimumSpan: TimeInterval = 2

    private var samples: [(date: Date, stepCount: Int)] = []

    /// The current step rate in steps per minute, or `nil` when there is not yet
    /// enough history to compute one.
    var stepsPerMinute: Int? {
        guard let first = samples.first, let last = samples.last else { return nil }

        let span = last.date.timeIntervalSince(first.date)
        guard span >= Self.minimumSpan else { return nil }

        let stepDelta = last.stepCount - first.stepCount
        guard stepDelta >= 0 else { return nil }

        return Int((Double(stepDelta) / span * 60).rounded())
    }

    // MARK: - Public Helpers

    /// Records a cumulative step count.
    /// - Parameters:
    ///   - stepCount: The cumulative step count from the machine.
    ///   - date: When the reading arrived. Defaults to now.
    mutating func record(stepCount: Int, at date: Date = Date()) {
        // A count that goes backwards means the machine reset its session, so the
        // old samples describe a workout that no longer exists.
        if let last = samples.last, stepCount < last.stepCount {
            samples.removeAll()
        }

        samples.append((date, stepCount))

        // Prune to the window, but never below two samples: if the machine goes
        // quiet for longer than the window, dropping to a single sample would make
        // the rate permanently uncomputable rather than merely stale.
        let cutoff = date.addingTimeInterval(-Self.windowDuration)
        while samples.count > 2, let first = samples.first, first.date < cutoff {
            // Dropping this sample must not shrink the remaining span below the
            // minimum, or the rate would blink out for a packet after a long gap.
            let remainingSpan = date.timeIntervalSince(samples[1].date)
            guard remainingSpan >= Self.minimumSpan else { break }
            samples.removeFirst()
        }
    }

    /// Discards all history, for use when a new capture session starts.
    mutating func reset() {
        samples.removeAll()
    }
}
