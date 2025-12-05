import HealthKit
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "WorkoutObserver")

/// Observes HealthKit for new workout completions.
final class WorkoutObserver {
    private let healthStore: HKHealthStore
    private var observerQuery: HKObserverQuery?

    /// Callback invoked when new workouts are detected.
    var onWorkoutDetected: ((HKWorkout) -> Void)?

    // MARK: - Initializer

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - Public Helpers

    /// Starts observing for workout changes.
    func startObserving() {
        let workoutType = HKObjectType.workoutType()
        logger.info("👀 Starting workout observer query...")

        observerQuery = HKObserverQuery(
            sampleType: workoutType,
            predicate: nil
        ) { [weak self] _, completionHandler, error in
            if let error {
                logger.error("❌ Observer query error: \(error.localizedDescription)")
                completionHandler()
                return
            }

            logger.info("🔔 Observer query fired!")

            Task {
                await self?.handleWorkoutUpdate()
                completionHandler()
            }
        }

        if let query = observerQuery {
            healthStore.execute(query)
            logger.info("✅ Observer query executing")
        }
    }

    /// Enables background delivery for workouts.
    func enableBackgroundDelivery() async throws {
        let workoutType = HKObjectType.workoutType()
        logger.info("📡 Enabling background delivery...")

        try await healthStore.enableBackgroundDelivery(
            for: workoutType,
            frequency: .immediate
        )
        logger.info("✅ Background delivery enabled successfully")
    }

    /// Stops observing workout changes.
    func stopObserving() {
        if let query = observerQuery {
            healthStore.stop(query)
            observerQuery = nil
            logger.info("🛑 Observer stopped")
        }
    }

    // MARK: - Private Helpers

    private func handleWorkoutUpdate() async {
        logger.info("🔄 Handling workout update...")

        let workoutType = HKObjectType.workoutType()

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            if let error {
                logger.error("❌ Sample query error: \(error.localizedDescription)")
                return
            }

            guard let workout = samples?.first as? HKWorkout else {
                logger.warning("⚠️ No workout found in samples")
                return
            }

            logger.info("✅ Found workout: \(workout.workoutActivityType.rawValue) - \(workout.uuid)")
            self?.onWorkoutDetected?(workout)
        }

        healthStore.execute(query)
    }
}
