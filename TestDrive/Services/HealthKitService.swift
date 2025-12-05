import HealthKit

/// Errors that can occur during HealthKit operations.
enum HealthKitError: Error {
    case notAvailable
    case authorizationFailed
    case queryFailed(Error)
}

/// Service responsible for HealthKit authorization and data access.
@Observable
final class HealthKitService {
    private let healthStore = HKHealthStore()

    /// The workout types to monitor.
    static let trackedWorkoutTypes: [HKWorkoutActivityType] = [
        .running,
        .walking,
        .cycling,
        .traditionalStrengthTraining,
        .functionalStrengthTraining,
        .highIntensityIntervalTraining,
        .yoga
    ]

    /// Authorization status for HealthKit.
    var isAuthorized = false

    // MARK: - Public Helpers

    /// Requests authorization to read workout data.
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let typesToRead: Set<HKObjectType> = [HKObjectType.workoutType()]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        isAuthorized = true
    }

    /// Fetches workouts from the last 30 days.
    /// - Returns: Array of HKWorkout objects sorted by start date (newest first).
    func fetchRecentWorkouts() async throws -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo,
            end: Date(),
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches the most recent workout.
    /// - Returns: The most recent HKWorkout or nil if none exists.
    func fetchMostRecentWorkout() async throws -> HKWorkout? {
        let workoutType = HKObjectType.workoutType()

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                let workout = samples?.first as? HKWorkout
                continuation.resume(returning: workout)
            }

            healthStore.execute(query)
        }
    }

    /// Returns the underlying HKHealthStore for observer queries.
    var store: HKHealthStore {
        healthStore
    }
}
