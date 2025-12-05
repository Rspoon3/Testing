import Foundation
import HealthKit

extension HKObserverQuery {
    /// Creates an AsyncStream that yields whenever the observer query detects changes.
    /// - Parameters:
    ///   - sampleType: The type of sample to observe.
    ///   - predicate: Optional predicate to filter samples.
    ///   - healthStore: The health store to execute the query on.
    /// - Returns: An AsyncStream that yields Void when changes are detected.
    static func stream(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        healthStore: HKHealthStore
    ) -> AsyncStream<Void> {
        AsyncStream { continuation in
            let query = HKObserverQuery(sampleType: sampleType, predicate: predicate) { _, completionHandler, error in
                if error == nil {
                    continuation.yield()
                }
                completionHandler()
            }

            healthStore.execute(query)

            continuation.onTermination = { @Sendable _ in
                healthStore.stop(query)
            }
        }
    }
}
