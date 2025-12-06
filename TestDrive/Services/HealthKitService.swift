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
    /// Shared health store instance - must be the same instance for background delivery to work.
    static let sharedHealthStore = HKHealthStore()

    private let healthStore = HealthKitService.sharedHealthStore

    /// The workout types to monitor.
    static let trackedWorkoutTypes: [HKWorkoutActivityType] = [
        .running,
        .walking,
        .cycling,
        .traditionalStrengthTraining,
        .functionalStrengthTraining,
        .highIntensityIntervalTraining,
        .yoga,
        .elliptical
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

        // Add heart rate for workout details
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            typesToRead.insert(heartRate)
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

    /// Fetches the previous workout before a given workout.
    /// - Parameter currentWorkout: The current workout to find the previous one before.
    /// - Returns: The previous HKWorkout or nil if none exists.
    func fetchPreviousWorkout(before currentWorkout: HKWorkout) async throws -> HKWorkout? {
        let workoutType = HKObjectType.workoutType()

        let predicate = HKQuery.predicateForSamples(
            withStart: nil,
            end: currentWorkout.startDate,
            options: .strictEndDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
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

    /// Fetches heart rate data for a specific workout.
    /// - Parameter workout: The workout to fetch heart rate data for.
    /// - Returns: WorkoutHeartRate with avg, max, and min BPM.
    func fetchHeartRate(for workout: HKWorkout) async -> WorkoutHeartRate {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return WorkoutHeartRate(averageBPM: nil, maxBPM: nil, minBPM: nil)
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                    continuation.resume(returning: WorkoutHeartRate(averageBPM: nil, maxBPM: nil, minBPM: nil))
                    return
                }

                let bpmUnit = HKUnit.count().unitDivided(by: .minute())
                let values = samples.map { $0.quantity.doubleValue(for: bpmUnit) }

                let avg = values.reduce(0, +) / Double(values.count)
                let max = values.max() ?? 0
                let min = values.min() ?? 0

                continuation.resume(returning: WorkoutHeartRate(
                    averageBPM: Int(avg),
                    maxBPM: Int(max),
                    minBPM: Int(min)
                ))
            }

            healthStore.execute(query)
        }
    }

    /// Calculates the current workout streak (consecutive days with workouts).
    /// - Returns: The number of consecutive days with workouts ending today or yesterday.
    func fetchWorkoutStreak() async -> Int {
        let workoutType = HKObjectType.workoutType()
        let calendar = Calendar.current
        let now = Date()

        // Fetch last 60 days of workouts to calculate streak
        let sixtyDaysAgo = calendar.date(byAdding: .day, value: -60, to: now)!

        let predicate = HKQuery.predicateForSamples(
            withStart: sixtyDaysAgo,
            end: now,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
                    continuation.resume(returning: 0)
                    return
                }

                // Get unique workout days
                var workoutDays = Set<Date>()
                for workout in workouts {
                    let day = calendar.startOfDay(for: workout.startDate)
                    workoutDays.insert(day)
                }

                // Calculate streak starting from today or yesterday
                let today = calendar.startOfDay(for: now)
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

                var streakStart: Date
                if workoutDays.contains(today) {
                    streakStart = today
                } else if workoutDays.contains(yesterday) {
                    streakStart = yesterday
                } else {
                    continuation.resume(returning: 0)
                    return
                }

                var streak = 0
                var currentDay = streakStart

                while workoutDays.contains(currentDay) {
                    streak += 1
                    guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else {
                        break
                    }
                    currentDay = previousDay
                }

                continuation.resume(returning: streak)
            }

            healthStore.execute(query)
        }
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

    /// Fetches weight statistics for the last 30 days.
    /// - Returns: WeightStats containing all weight entries and calculated statistics.
    func fetchWeightStats() async -> WeightStats {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return WeightStats(
                entries: [],
                currentWeight: nil,
                previousWeight: nil,
                monthAgoWeight: nil,
                minWeight: nil,
                maxWeight: nil,
                averageWeight: nil
            )
        }

        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!

        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo,
            end: now,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                    continuation.resume(returning: WeightStats(
                        entries: [],
                        currentWeight: nil,
                        previousWeight: nil,
                        monthAgoWeight: nil,
                        minWeight: nil,
                        maxWeight: nil,
                        averageWeight: nil
                    ))
                    return
                }

                let entries = samples.map { sample in
                    WeightEntry(
                        id: sample.uuid.uuidString,
                        weightInPounds: sample.quantity.doubleValue(for: .pound()),
                        date: sample.startDate
                    )
                }

                let weights = entries.map(\.weightInPounds)
                let currentWeight = entries.first?.weightInPounds
                let previousWeight = entries.count > 1 ? entries[1].weightInPounds : nil
                let monthAgoWeight = entries.last?.weightInPounds

                continuation.resume(returning: WeightStats(
                    entries: entries,
                    currentWeight: currentWeight,
                    previousWeight: previousWeight,
                    monthAgoWeight: monthAgoWeight,
                    minWeight: weights.min(),
                    maxWeight: weights.max(),
                    averageWeight: weights.isEmpty ? nil : weights.reduce(0, +) / Double(weights.count)
                ))
            }

            healthStore.execute(query)
        }
    }

    /// Fetches the most recent weight entry.
    /// - Returns: The most recent WeightEntry or nil if none exists.
    func fetchMostRecentWeightEntry() async -> WeightEntry? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
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
    }
}
