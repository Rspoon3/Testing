//
//  TimerStreamable.swift
//
//
//  Created by Richard Witherspoon on 12/13/23.
//

import Foundation

public protocol TimerStreamable {
    static func stream(
        every interval: Duration,
        tolerance: TimeInterval?,
        endIn endInterval: Duration?
    ) -> AsyncStream<Date>
}

public extension TimerStreamable {
    static func stream(
        every interval: Duration,
        endIn endInterval: Duration?
    ) -> AsyncStream<Date> {
        stream(
            every: interval,
            tolerance: nil,
            endIn: endInterval
        )
    }
}

extension Timer: TimerStreamable, @unchecked Sendable {
    
    /// Returns an `AsyncStream<Date>` that repeatedly emits the current date on the given interval.
    ///
    /// - Parameters:
    ///   - interval: The time interval on which to publish events. For example, a value of `0.5` publishes an event approximately every half-second.
    ///   - tolerance: The allowed timing variance when emitting events. Defaults to `nil`, which allows any variance.
    ///   - endInterval: An optional time interval to end the stream. If it's less than the timer interval, the stream will automatically finish.
    /// - Returns: An `AsyncPublisher` that repeatedly emits the current date on the given interval.
    public static func stream(
        every interval: Duration,
        tolerance: TimeInterval? = nil,
        endIn endInterval: Duration? = nil
    ) -> AsyncStream<Date> {
        AsyncStream { continuation in
            let timer = Timer.scheduledTimer(withTimeInterval: interval.timeInterval, repeats: true) { timer in
                continuation.yield(.now)
            }
            
            if let tolerance {
                timer.tolerance = tolerance
            }
            
            let endTimer: Timer? = if let endTimeInterval = endInterval?.timeInterval {
                Timer.scheduledTimer(withTimeInterval: endTimeInterval, repeats: false) { _ in
                    continuation.finish()
                }
            } else {
                nil
            }
            
            continuation.onTermination = {  _ in
                endTimer?.invalidate()
                timer.invalidate()
            }
            
            guard let endInterval, endInterval > interval else {
                continuation.finish()
                return
            }
        }
    }
}


#if DEBUG
public enum MockTimerStreamable: TimerStreamable {
    
    public static func stream(
        every interval: Duration,
        tolerance: TimeInterval?,
        endIn endInterval: Duration?
    ) -> AsyncStream<Date> {
        AsyncStream { continuation in
            if let timeInterval = endInterval?.timeInterval {
                let iterations = Int(timeInterval / interval.timeInterval)
                for _ in 0 ..< iterations {
                    continuation.yield(.now)
                }
                continuation.finish()
            } else {
                continuation.yield(.now)
                continuation.finish()
            }
        }
    }
}
#endif
