//
//  Duration+Countdown.swift
//  TestDrive
//

import Foundation

extension Duration {
    /// Renders the duration as `H:MM:SS` when it's at least one hour long,
    /// or `M:SS` otherwise.
    ///
    /// `.time(pattern: .minuteSecond)` keeps growing the minutes field
    /// (e.g. "171:46" for ~2h 51m), and `.hourMinuteSecond` always renders
    /// the hour slot even when the duration is short (e.g. "0:05:12").
    /// This helper picks the right pattern based on magnitude so meeting
    /// countdowns read naturally at any range.
    func formattedCountdown() -> String {
        if abs(components.seconds) >= 3_600 {
            return formatted(.time(pattern: .hourMinuteSecond))
        }
        return formatted(.time(pattern: .minuteSecond))
    }
}
