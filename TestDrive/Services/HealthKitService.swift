import HealthKit
import CoreLocation
import os

/// Fetches HealthKit workouts and their associated route data.
final class HealthKitService: Sendable {
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "HealthKit")

    /// Requests read authorization for workouts and route data.
    func requestAuthorization() async throws {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    /// Fetches all workouts that have associated route data, sorted by date descending.
    /// - Parameter limit: Maximum number of workouts to return.
    /// - Returns: An array of `HKWorkout` objects that have at least one route.
    func fetchWorkoutsWithRoutes(limit: Int = HKObjectQueryNoLimit) async throws -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let workouts: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let results = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: results)
            }
            healthStore.execute(query)
        }

        logger.info("Fetched \(workouts.count) workouts from HealthKit")

        let workoutsWithRoutes = try await filterWorkoutsWithRoutes(workouts)

        logger.info("Found \(workoutsWithRoutes.count) workouts with route data")
        return workoutsWithRoutes
    }

    /// Filters workouts to only those with route data, checking in parallel with bounded concurrency.
    private func filterWorkoutsWithRoutes(_ workouts: [HKWorkout]) async throws -> [HKWorkout] {
        let maxConcurrency = 10

        return try await withThrowingTaskGroup(of: (Int, HKWorkout, Bool).self) { group in
            var iterator = workouts.enumerated().makeIterator()
            var inFlight = 0

            while inFlight < maxConcurrency, let (index, workout) = iterator.next() {
                group.addTask {
                    let routes = try await self.fetchRoutes(for: workout)
                    return (index, workout, !routes.isEmpty)
                }
                inFlight += 1
            }

            var results: [(Int, HKWorkout)] = []

            for try await (index, workout, hasRoutes) in group {
                if hasRoutes {
                    results.append((index, workout))
                }
                if let (nextIndex, nextWorkout) = iterator.next() {
                    group.addTask {
                        let routes = try await self.fetchRoutes(for: nextWorkout)
                        return (nextIndex, nextWorkout, !routes.isEmpty)
                    }
                }
            }

            return results
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
    }

    /// Fetches route objects for a given workout.
    func fetchRoutes(for workout: HKWorkout) async throws -> [HKWorkoutRoute] {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let routes = (samples as? [HKWorkoutRoute]) ?? []
                continuation.resume(returning: routes)
            }
            healthStore.execute(query)
        }
    }

    /// Fetches all CLLocation points from a workout route.
    func fetchRouteLocations(for route: HKWorkoutRoute) async throws -> [CLLocation] {
        try await withCheckedThrowingContinuation { continuation in
            nonisolated(unsafe) var allLocations: [CLLocation] = []
            nonisolated(unsafe) var hasResumed = false

            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                guard !hasResumed else { return }

                if let error {
                    hasResumed = true
                    continuation.resume(throwing: error)
                    return
                }

                if let locations {
                    allLocations.append(contentsOf: locations)
                }

                if done {
                    hasResumed = true
                    continuation.resume(returning: allLocations)
                }
            }
            healthStore.execute(query)
        }
    }

    /// Fetches all locations for a workout by aggregating all its routes.
    func fetchAllLocations(for workout: HKWorkout) async throws -> [CLLocation] {
        let routes = try await fetchRoutes(for: workout)
        var allLocations: [CLLocation] = []

        for route in routes {
            let locations = try await fetchRouteLocations(for: route)
            allLocations.append(contentsOf: locations)
        }

        return allLocations
    }
}
