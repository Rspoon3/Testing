import HealthKit
import UIKit
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "WorkoutObserver")

/// Observes HealthKit for new workout completions and weight entries.
final class HealthObserver {
    private let healthStore: HKHealthStore
    private var workoutObserverQuery: HKObserverQuery?
    private var weightObserverQuery: HKObserverQuery?

    /// Callback invoked when new workouts are detected.
    var onWorkoutDetected: ((HKWorkout) async -> Void)?

    /// Callback invoked when new weight entries are detected.
    var onWeightDetected: ((WeightEntry) async -> Void)?

    // MARK: - Initializer

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - Public Helpers

    /// Starts observing for workout and weight changes.
    func startObserving() {
        startWorkoutObserver()
        startWeightObserver()
    }

    /// Enables background delivery for workouts and weight.
    func enableBackgroundDelivery() async throws {
        let workoutType = HKObjectType.workoutType()
        logger.info("📡 Enabling background delivery for workouts...")

        try await healthStore.enableBackgroundDelivery(
            for: workoutType,
            frequency: .immediate
        )
        logger.info("✅ Workout background delivery enabled")

        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            logger.info("📡 Enabling background delivery for weight...")
            try await healthStore.enableBackgroundDelivery(
                for: weightType,
                frequency: .immediate
            )
            logger.info("✅ Weight background delivery enabled")
        }
    }

    /// Stops observing all changes.
    func stopObserving() {
        if let query = workoutObserverQuery {
            healthStore.stop(query)
            workoutObserverQuery = nil
            logger.info("🛑 Workout observer stopped")
        }

        if let query = weightObserverQuery {
            healthStore.stop(query)
            weightObserverQuery = nil
            logger.info("🛑 Weight observer stopped")
        }
    }

    // MARK: - Private Helpers

    private func startWorkoutObserver() {
        let workoutType = HKObjectType.workoutType()
        logger.info("👀 Starting workout observer query...")

        workoutObserverQuery = HKObserverQuery(
            sampleType: workoutType,
            predicate: nil
        ) { [weak self] _, completionHandler, error in
            if let error {
                logger.error("❌ Workout observer error: \(error.localizedDescription)")
                completionHandler()
                return
            }

            logger.info("🔔 Workout observer fired!")

            // All UI API calls must happen on main thread
            DispatchQueue.main.async {
                // Test notification to verify observer is firing
                Task {
                    await NotificationService.shared.scheduleNotification(
                        title: "🧪 Workout Observer",
                        body: "Observer fired at \(Date().formatted(date: .omitted, time: .standard))",
                        delay: 0.5
                    )
                }

                // Request background time for processing
                var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
                backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "ProcessWorkout") {
                    logger.warning("⚠️ Workout background task expired")
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    backgroundTaskID = .invalid
                }

                Task { [weak self] in
                    await self?.handleWorkoutUpdate()
                    completionHandler()

                    if backgroundTaskID != .invalid {
                        await MainActor.run {
                            UIApplication.shared.endBackgroundTask(backgroundTaskID)
                        }
                    }
                }
            }
        }

        if let query = workoutObserverQuery {
            healthStore.execute(query)
            logger.info("✅ Workout observer executing")
        }
    }

    private func startWeightObserver() {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            logger.error("❌ Could not get weight type")
            return
        }

        logger.info("👀 Starting weight observer query...")

        weightObserverQuery = HKObserverQuery(
            sampleType: weightType,
            predicate: nil
        ) { [weak self] _, completionHandler, error in
            if let error {
                logger.error("❌ Weight observer error: \(error.localizedDescription)")
                completionHandler()
                return
            }

            logger.info("🔔 Weight observer fired!")

            // All UI API calls must happen on main thread
            DispatchQueue.main.async {
                // Test notification to verify observer is firing
                Task {
                    await NotificationService.shared.scheduleNotification(
                        title: "🧪 Weight Observer",
                        body: "Observer fired at \(Date().formatted(date: .omitted, time: .standard))",
                        delay: 0.5
                    )
                }

                // Request background time for processing
                var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
                backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "ProcessWeight") {
                    logger.warning("⚠️ Weight background task expired")
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    backgroundTaskID = .invalid
                }

                Task { [weak self] in
                    await self?.handleWeightUpdate()
                    completionHandler()

                    if backgroundTaskID != .invalid {
                        await MainActor.run {
                            UIApplication.shared.endBackgroundTask(backgroundTaskID)
                        }
                    }
                }
            }
        }

        if let query = weightObserverQuery {
            healthStore.execute(query)
            logger.info("✅ Weight observer executing")
        }
    }

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
