//
//  StepRateTrackerTests.swift
//  TestDriveTests
//

import Foundation
import Testing
@testable import TestDrive

/// Checks the derived steps-per-minute figure.
///
/// The machine never transmits a step rate — its SPEED level occupies the FTMS Step
/// Per Minute field and Average Step Rate is always zero — so this value is
/// reconstructed from successive step counts and has to be right on its own terms.
@Suite("Step rate tracker")
struct StepRateTrackerTests {

    private let start = Date(timeIntervalSince1970: 1_000_000)

    @Test("No rate is offered from a single reading")
    func singleReadingHasNoRate() {
        var tracker = StepRateTracker()
        tracker.record(stepCount: 10, at: start)

        #expect(tracker.stepsPerMinute == nil)
    }

    @Test("No rate is offered until the minimum span is covered")
    func waitsForMinimumSpan() {
        var tracker = StepRateTracker()
        tracker.record(stepCount: 0, at: start)
        tracker.record(stepCount: 1, at: start.addingTimeInterval(1))

        #expect(tracker.stepsPerMinute == nil)
    }

    @Test("A steady cadence produces that cadence")
    func steadyCadence() {
        // One step a second is 60 step/min.
        var tracker = StepRateTracker()
        for second in 0...5 {
            tracker.record(stepCount: second, at: start.addingTimeInterval(Double(second)))
        }

        #expect(tracker.stepsPerMinute == 60)
    }

    @Test("Matches the rate observed in the captured session")
    func matchesCapturedSession() {
        // From the capture: steps 43 → 48 over five seconds while climbing at
        // speed 6, which the app reported as 60 step/min.
        var tracker = StepRateTracker()
        let counts = [43, 44, 45, 46, 47, 48]
        for (offset, count) in counts.enumerated() {
            tracker.record(stepCount: count, at: start.addingTimeInterval(Double(offset)))
        }

        #expect(tracker.stepsPerMinute == 60)
    }

    @Test("A stopped machine reports zero, not a stale rate")
    func stoppedMachineReportsZero() {
        var tracker = StepRateTracker()
        for second in 0...5 {
            tracker.record(stepCount: second, at: start.addingTimeInterval(Double(second)))
        }
        #expect(tracker.stepsPerMinute == 60)

        // The count stops advancing while packets keep arriving.
        for second in 6...14 {
            tracker.record(stepCount: 5, at: start.addingTimeInterval(Double(second)))
        }

        #expect(tracker.stepsPerMinute == 0)
    }

    @Test("The window drops old samples so a speed change is reflected")
    func windowFollowsSpeedChange() {
        var tracker = StepRateTracker()
        var elapsed = 0.0
        var steps = 0

        // Six seconds at 120 step/min: a step every half second, sampled every
        // half second.
        while elapsed < 6 {
            tracker.record(stepCount: steps, at: start.addingTimeInterval(elapsed))
            elapsed += 0.5
            steps += 1
        }
        #expect(tracker.stepsPerMinute == 120)

        // Then ten seconds at 30 step/min: a step every two seconds, still sampled
        // every half second. That is long enough for the faster samples to age out
        // of the six-second window entirely.
        for sample in 0..<20 {
            elapsed += 0.5
            if sample.isMultiple(of: 4) { steps += 1 }
            tracker.record(stepCount: steps, at: start.addingTimeInterval(elapsed))
        }

        let rate = tracker.stepsPerMinute
        #expect(rate != nil)
        #expect(
            rate ?? .max <= 40,
            "expected the 120 step/min samples to have aged out, leaving roughly 30, got \(rate.map(String.init) ?? "nil")"
        )
    }

    @Test("A session reset discards the previous workout")
    func sessionResetDiscardsHistory() {
        // The machine resets its cumulative counters between sessions, which was
        // observed live: the first packet of one capture carried 48 steps before the
        // machine dropped back to 0. Differencing across that boundary would produce
        // a large negative delta.
        var tracker = StepRateTracker()
        for second in 0...5 {
            tracker.record(stepCount: 40 + second, at: start.addingTimeInterval(Double(second)))
        }
        #expect(tracker.stepsPerMinute == 60)

        tracker.record(stepCount: 0, at: start.addingTimeInterval(6))
        #expect(tracker.stepsPerMinute == nil)

        // A fresh cadence is then measured from scratch. The reset packet itself is
        // retained as the new baseline, so the span runs from it: six steps over the
        // six seconds from t=6 to t=12.
        for second in 7...12 {
            tracker.record(stepCount: second - 6, at: start.addingTimeInterval(Double(second)))
        }
        #expect(tracker.stepsPerMinute == 60)
    }

    @Test("A rate survives packets arriving further apart than the window")
    func survivesGapsLongerThanWindow() {
        // If pruning were unconditional, a gap longer than the window would leave a
        // single sample and the rate would become permanently uncomputable.
        var tracker = StepRateTracker()
        tracker.record(stepCount: 0, at: start)
        tracker.record(stepCount: 30, at: start.addingTimeInterval(30))

        #expect(tracker.stepsPerMinute == 60)
    }

    @Test("Reset clears all history")
    func resetClearsHistory() {
        var tracker = StepRateTracker()
        for second in 0...5 {
            tracker.record(stepCount: second, at: start.addingTimeInterval(Double(second)))
        }
        #expect(tracker.stepsPerMinute != nil)

        tracker.reset()
        #expect(tracker.stepsPerMinute == nil)
    }
}
