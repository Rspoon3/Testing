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

    /// Requests authorization to read workout and profile data.
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        var typesToRead: Set<HKObjectType> = [HKObjectType.workoutType()]

        // Add characteristic types
        if let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) {
            typesToRead.insert(biologicalSex)
        }
        if let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            typesToRead.insert(dateOfBirth)
        }

        // Add quantity types for weight and height
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            typesToRead.insert(weight)
        }
        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            typesToRead.insert(height)
        }

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

    /// Fetches the user's profile data from HealthKit.
    /// - Returns: UserProfile with available data.
    func fetchUserProfile() async -> UserProfile {
        // Get age from date of birth
        var age: Int?
        if let dateOfBirth = try? healthStore.dateOfBirthComponents().date {
            age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year
        }

        // Get biological sex
        var biologicalSex: HKBiologicalSex?
        if let sex = try? healthStore.biologicalSex().biologicalSex {
            biologicalSex = sex
        }

        // Get most recent weight
        let weight = await fetchMostRecentQuantity(for: .bodyMass, unit: .pound())

        // Get most recent height
        let height = await fetchMostRecentQuantity(for: .height, unit: .inch())

        return UserProfile(
            age: age,
            biologicalSex: biologicalSex,
            weightInPounds: weight,
            heightInInches: height
        )
    }

    // MARK: - Private Helpers

    private func fetchMostRecentQuantity(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches workout statistics for today, last 7 days, and last 30 days.
    /// - Returns: WorkoutStats containing aggregated data for all periods.
    func fetchWorkoutStats() async throws -> WorkoutStats {
        let workoutType = HKObjectType.workoutType()
        let calendar = Calendar.current
        let now = Date()

        // Get last 30 days of workouts (includes today and weekly)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!

        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo,
            end: now,
            options: .strictStartDate
        )

        let allWorkouts: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
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

        // Filter workouts by period
        let startOfToday = calendar.startOfDay(for: now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        let todayWorkouts = allWorkouts.filter { $0.startDate >= startOfToday }
        let weeklyWorkouts = allWorkouts.filter { $0.startDate >= sevenDaysAgo }

        return WorkoutStats(
            today: PeriodWorkoutStats.from(workouts: todayWorkouts, period: .today),
            weekly: PeriodWorkoutStats.from(workouts: weeklyWorkouts, period: .week),
            monthly: PeriodWorkoutStats.from(workouts: allWorkouts, period: .month)
        )
    }
}
