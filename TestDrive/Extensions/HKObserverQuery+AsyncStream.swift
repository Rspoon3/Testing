import Foundation
import HealthKit

/// A sendable wrapper that signals to HealthKit that background processing is complete.
///
/// Call ``callAsFunction()`` (or just `completion()`) **after** all async work is finished.
/// This is critical for iOS 26+, which aggressively suspends apps after the completion handler is called.
final class HKObserverQueryCompletion: Sendable {
    private nonisolated(unsafe) let handler: () -> Void

    init(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    func callAsFunction() {
        handler()
    }
}

extension HKObserverQuery {
    /// Creates an `AsyncStream` that yields a completion handler whenever the observer query detects changes.
    ///
    /// ## Background Delivery Requirements
    ///
    /// For HealthKit background delivery to work correctly on iOS 26+, you must call
    /// the completion handler **after** all processing is done. Calling it prematurely signals
    /// to iOS that the app is done with its work, allowing the system to suspend the app.
    ///
    /// ## Usage
    /// ```swift
    /// let stream = HKObserverQuery.stream(
    ///     sampleType: workoutType,
    ///     predicate: nil,
    ///     healthStore: healthStore
    /// )
    ///
    /// for await completion in stream {
    ///     await processWorkout()
    ///     completion()  // Call AFTER work completes
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - sampleType: The type of sample to observe.
    ///   - predicate: Optional predicate to filter samples.
    ///   - healthStore: The health store to execute the query on.
    /// - Returns: An `AsyncStream` that yields a completion handler when changes are detected.
    static func stream(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        healthStore: HKHealthStore
    ) -> AsyncStream<HKObserverQueryCompletion> {
        AsyncStream { continuation in
            let query = HKObserverQuery(sampleType: sampleType, predicate: predicate) { _, completionHandler, error in
                guard error == nil else {
                    completionHandler()
                    return
                }

                continuation.yield(HKObserverQueryCompletion(completionHandler))
            }

            healthStore.execute(query)

            continuation.onTermination = { @Sendable _ in
                healthStore.stop(query)
            }
        }
    }
}
