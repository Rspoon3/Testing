import HealthKit
import os.log

private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "HealthObserver")
private let debugLogger = DebugLogger.shared

/// Observes HealthKit for new workout completions and weight entries.
///
/// This class uses `HKObserverQuery` to monitor HealthKit for changes, enabling the app
/// to be woken in the background when new data is available.
///
/// ## Background Delivery Requirements
///
/// For background delivery to work correctly, the `HKObserverQuery` completion handler
/// must be called **after** all processing is complete. Calling it prematurely signals
/// to iOS that the app is done with its work, allowing the system to suspend the app
/// before processing finishes.
///
/// ### Correct Pattern
/// ```swift
/// HKObserverQuery(sampleType: type, predicate: nil) { _, completionHandler, _ in
///     Task {
///         await self.processData()
///         completionHandler()  // Called AFTER work completes
///     }
/// }
/// ```
///
/// ### Incorrect Pattern (causes issues on iOS 26+)
/// ```swift
/// HKObserverQuery(sampleType: type, predicate: nil) { _, completionHandler, _ in
///     completionHandler()  // Called immediately - app may suspend before work completes
///     Task { await self.processData() }
/// }
/// ```
///
/// - Note: iOS 26 is more aggressive about suspending apps after `completionHandler()` is called.
///   Always ensure all async work completes before calling the completion handler.
final class HealthObserver {
    private let healthStore: HKHealthStore
    private var workoutQuery: HKObserverQuery?
    private var weightQuery: HKObserverQuery?

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
        debugLogger.log("Starting HealthKit observers...", category: .observer)
        await enableBackgroundDelivery()

        debugLogger.log("Background delivery enabled, starting workout and weight observers", category: .observer)

        observeWorkouts()
        observeWeight()
    }

    // MARK: - Private Helpers

    /// Enables background delivery for workouts and weight.
    private func enableBackgroundDelivery() async {
        let workoutType = HKObjectType.workoutType()

        do {
            try await healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate)
            logger.info("✅ Workout background delivery enabled")
            debugLogger.log("Workout background delivery enabled successfully", category: .observer)
        } catch {
            logger.error("❌ Failed to enable workout background delivery: \(error.localizedDescription)")
            debugLogger.log("FAILED to enable workout background delivery: \(error.localizedDescription)", category: .error)
        }

        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            do {
                try await healthStore.enableBackgroundDelivery(for: weightType, frequency: .immediate)
                logger.info("✅ Weight background delivery enabled")
                debugLogger.log("Weight background delivery enabled successfully", category: .observer)
            } catch {
                logger.error("❌ Failed to enable weight background delivery: \(error.localizedDescription)")
                debugLogger.log("FAILED to enable weight background delivery: \(error.localizedDescription)", category: .error)
            }
        }
    }

    /// Starts observing workout updates using `HKObserverQuery`.
    ///
    /// The query runs indefinitely and fires whenever HealthKit detects new workout data.
    /// The completion handler is intentionally called **after** `handleWorkoutUpdate()` completes
    /// to ensure all background work finishes before iOS suspends the app.
    private func observeWorkouts() {
        debugLogger.log("Workout observer starting...", category: .observer)
        let workoutType = HKObjectType.workoutType()

        workoutQuery = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] _, completionHandler, error in
            guard let self else {
                completionHandler()
                return
            }

            if let error {
                logger.error("❌ Workout observer error: \(error.localizedDescription)")
                debugLogger.log("Workout observer error: \(error.localizedDescription)", category: .error)
                completionHandler()
                return
            }

            logger.info("🔔 Workout observer fired!")
            debugLogger.log("WORKOUT OBSERVER FIRED - Query callback received", category: .workout)

            Task {
                await self.handleWorkoutUpdate()
                completionHandler()
            }
        }

        if let workoutQuery {
            healthStore.execute(workoutQuery)
            debugLogger.log("Workout observer query executed", category: .observer)
        }
    }

    /// Starts observing weight updates using `HKObserverQuery`.
    ///
    /// The query runs indefinitely and fires whenever HealthKit detects new weight data.
    /// The completion handler is intentionally called **after** `handleWeightUpdate()` completes
    /// to ensure all background work finishes before iOS suspends the app.
    private func observeWeight() {
        debugLogger.log("Weight observer starting...", category: .observer)
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            logger.error("❌ Could not get weight type")
            debugLogger.log("FAILED to get weight type for observer", category: .error)
            return
        }

        weightQuery = HKObserverQuery(sampleType: weightType, predicate: nil) { [weak self] _, completionHandler, error in
            guard let self else {
                completionHandler()
                return
            }

            if let error {
                logger.error("❌ Weight observer error: \(error.localizedDescription)")
                debugLogger.log("Weight observer error: \(error.localizedDescription)", category: .error)
                completionHandler()
                return
            }

            logger.info("🔔 Weight observer fired!")
            debugLogger.log("WEIGHT OBSERVER FIRED - Query callback received", category: .weight)

            Task {
                await self.handleWeightUpdate()
                completionHandler()
            }
        }

        if let weightQuery {
            healthStore.execute(weightQuery)
            debugLogger.log("Weight observer query executed", category: .observer)
        }
    }

    /// Fetches the most recent workout and notifies callback.
    private func handleWorkoutUpdate() async {
        logger.info("🔄 Handling workout update...")
        debugLogger.log("Handling workout update - fetching most recent workout...", category: .workout)

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
                    debugLogger.log("Sample query error: \(error.localizedDescription)", category: .error)
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
            debugLogger.log("No workout found in samples after observer fired", category: .workout)
            return
        }

        let workoutInfo = "type=\(workout.workoutActivityType.rawValue), uuid=\(workout.uuid), date=\(workout.endDate)"
        logger.info("✅ Found workout: \(workout.workoutActivityType.rawValue) - \(workout.uuid)")
        debugLogger.log("WORKOUT DETECTED: \(workoutInfo)", category: .workout)
        await onWorkoutDetected?(workout)
    }

    /// Fetches the most recent weight entry and notifies callback.
    private func handleWeightUpdate() async {
        logger.info("🔄 Handling weight update...")
        debugLogger.log("Handling weight update - fetching most recent entry...", category: .weight)

        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            debugLogger.log("Failed to get weight type", category: .error)
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
                    debugLogger.log("Weight query error: \(error.localizedDescription)", category: .error)
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
            debugLogger.log("No weight entry found in samples after observer fired", category: .weight)
            return
        }

        let weightInfo = "weight=\(entry.formattedWeight), id=\(entry.id), date=\(entry.date)"
        logger.info("✅ Found weight entry: \(entry.formattedWeight) - \(entry.id)")
        debugLogger.log("WEIGHT DETECTED: \(weightInfo)", category: .weight)
        await onWeightDetected?(entry)
    }
}
