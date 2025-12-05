import HealthKit
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "HealthObserver")

/// Observes HealthKit for new workout completions and weight entries.
final class HealthObserver {
    private let healthStore: HKHealthStore

    /// Callback invoked when new workouts are detected.
    var onWorkoutDetected: ((HKWorkout) async -> Void)?

    /// Callback invoked when new weight entries are detected.
    var onWeightDetected: ((WeightEntry) async -> Void)?

    // MARK: - Initializer

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - Public Helpers

    /// Enables background delivery and starts observing for workout and weight changes.
    /// Must be called from application(_:didFinishLaunchingWithOptions:).
    func startObserving() async {
        await enableBackgroundDelivery()

        // Run both observers concurrently (they use infinite AsyncStreams)
        async let workoutTask: () = observeWorkouts()
        async let weightTask: () = observeWeight()
        _ = await (workoutTask, weightTask)
    }

    // MARK: - Private Helpers

    /// Enables background delivery for workouts and weight.
    private func enableBackgroundDelivery() async {
        let workoutType = HKObjectType.workoutType()

        do {
            try await healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate)
            logger.info("✅ Workout background delivery enabled")
        } catch {
            logger.error("❌ Failed to enable workout background delivery: \(error.localizedDescription)")
        }

        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            do {
                try await healthStore.enableBackgroundDelivery(for: weightType, frequency: .immediate)
                logger.info("✅ Weight background delivery enabled")
            } catch {
                logger.error("❌ Failed to enable weight background delivery: \(error.localizedDescription)")
            }
        }
    }

    /// Observes workout updates using AsyncStream.
    private func observeWorkouts() async {
        let workoutType = HKObjectType.workoutType()

        let stream = HKObserverQuery.stream(
            sampleType: workoutType,
            predicate: nil,
            healthStore: healthStore
        )

        for await _ in stream {
            logger.info("🔔 Workout observer fired!")
            await handleWorkoutUpdate()
        }
    }

    /// Observes weight updates using AsyncStream.
    private func observeWeight() async {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            logger.error("❌ Could not get weight type")
            return
        }

        let stream = HKObserverQuery.stream(
            sampleType: weightType,
            predicate: nil,
            healthStore: healthStore
        )

        for await _ in stream {
            logger.info("🔔 Weight observer fired!")
            await handleWeightUpdate()
        }
    }

    /// Fetches the most recent workout and notifies callback.
    private func handleWorkoutUpdate() async {
        logger.info("🔄 Handling workout update...")

        let workoutType = HKObjectType.workoutType()

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        let workout: HKWorkout? = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    logger.error("❌ Sample query error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                let workout = samples?.first as? HKWorkout
                continuation.resume(returning: workout)
            }

            healthStore.execute(query)
        }

        guard let workout else {
            logger.warning("⚠️ No workout found in samples")
            return
        }

        logger.info("✅ Found workout: \(workout.workoutActivityType.rawValue) - \(workout.uuid)")
        await onWorkoutDetected?(workout)
    }

    /// Fetches the most recent weight entry and notifies callback.
    private func handleWeightUpdate() async {
        logger.info("🔄 Handling weight update...")

        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return
        }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        let entry: WeightEntry? = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    logger.error("❌ Weight query error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let entry = WeightEntry(
                    id: sample.uuid.uuidString,
                    weightInPounds: sample.quantity.doubleValue(for: .pound()),
                    date: sample.startDate
                )
                continuation.resume(returning: entry)
            }

            healthStore.execute(query)
        }

        guard let entry else {
            logger.warning("⚠️ No weight found in samples")
            return
        }

        logger.info("✅ Found weight entry: \(entry.formattedWeight) - \(entry.id)")
        await onWeightDetected?(entry)
    }
}
