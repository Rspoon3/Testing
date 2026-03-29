import HealthKit
import UIKit
import os

/// View model that orchestrates fetching workouts and generating map snapshots.
@Observable
final class WorkoutMapViewModel {
    private(set) var workouts: [HKWorkout] = []
    private(set) var snapshots: [HKWorkout: UIImage] = [:]
    private(set) var timings: [HKWorkout: SnapshotTiming] = [:]
    private(set) var isLoading = false
    private(set) var isGeneratingSnapshots = false
    private(set) var errorMessage: String?
    private(set) var snapshotsCompleted = 0
    private(set) var snapshotsTotal = 0

    let stats = BenchmarkStats()
    private(set) var fetchStats = FetchStats()

    private let healthKitService = HealthKitService()
    private let snapshotService = MapSnapshotService()
    private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "WorkoutMap")

    // MARK: - Public Helpers

    /// Loads workouts from HealthKit and generates snapshots for each.
    func loadWorkouts() async {
        isLoading = true
        errorMessage = nil
        stats.reset()
        snapshots.removeAll()
        timings.removeAll()
        snapshotsCompleted = 0

        do {
            let authStart = ContinuousClock.now
            try await healthKitService.requestAuthorization()
            let authDuration = authStart.duration(to: .now)

            let fetchStart = ContinuousClock.now
            workouts = try await healthKitService.fetchWorkoutsWithRoutes()
            let fetchDuration = fetchStart.duration(to: .now)

            fetchStats = FetchStats(
                authorizationDuration: authDuration,
                workoutFetchDuration: fetchDuration,
                totalWorkoutsFetched: workouts.count
            )

            logger.info("""
            Fetch complete — \
            auth: \(authDuration.milliseconds, format: .fixed(precision: 1))ms, \
            fetch: \(fetchDuration.milliseconds, format: .fixed(precision: 1))ms, \
            workouts: \(self.workouts.count)
            """)

            snapshotsTotal = workouts.count
            isLoading = false

            guard !workouts.isEmpty else {
                errorMessage = "No workouts with route data found."
                return
            }

            isGeneratingSnapshots = true
            let batchStart = ContinuousClock.now

            await generateAllSnapshots()

            let batchDuration = batchStart.duration(to: .now)
            fetchStats.snapshotBatchDuration = batchDuration
            fetchStats.totalDuration = authStart.duration(to: .now)
            isGeneratingSnapshots = false

            logger.info("""
            All snapshots complete — \
            count: \(self.stats.count), \
            total batch: \(batchDuration.milliseconds, format: .fixed(precision: 1))ms, \
            avg: \(self.stats.averageTotalMs, format: .fixed(precision: 1))ms, \
            end-to-end: \(self.fetchStats.totalDurationMs, format: .fixed(precision: 1))ms
            """)
        } catch {
            isLoading = false
            isGeneratingSnapshots = false
            errorMessage = error.localizedDescription
            logger.error("Failed to load workouts: \(error.localizedDescription)")
        }
    }

    /// Generates a JSON string of all benchmark data for export.
    func exportBenchmarkJSON() -> String {
        let data: [String: Any] = [
            "fetchStats": [
                "authorizationMs": fetchStats.authorizationMs,
                "workoutFetchMs": fetchStats.workoutFetchMs,
                "totalWorkoutsFetched": fetchStats.totalWorkoutsFetched,
                "averageLocationFetchMs": fetchStats.averageLocationFetchMs,
                "snapshotBatchMs": fetchStats.snapshotBatchMs,
                "averagePerWorkoutMs": fetchStats.averagePerWorkoutMs,
                "endToEndMs": fetchStats.totalDurationMs
            ],
            "snapshotStats": [
                "count": stats.count,
                "averageTotalMs": stats.averageTotalMs,
                "minTotalMs": stats.minTotalMs,
                "maxTotalMs": stats.maxTotalMs,
                "medianTotalMs": stats.medianTotalMs,
                "stdDevTotalMs": stats.stdDevTotalMs,
                "p95TotalMs": stats.p95TotalMs,
                "p99TotalMs": stats.p99TotalMs,
                "averageSnapshotGenerationMs": stats.averageSnapshotGenerationMs,
                "averageRouteDrawingMs": stats.averageRouteDrawingMs,
                "averageRegionCalculationMs": stats.averageRegionCalculationMs,
                "totalLocationPoints": stats.totalLocationPoints,
                "averageLocationPoints": stats.averageLocationPoints
            ],
            "perWorkout": stats.results.enumerated().map { index, result in
                [
                    "index": index,
                    "totalMs": result.timing.totalMs,
                    "snapshotGenerationMs": result.timing.snapshotGenerationMs,
                    "routeDrawingMs": result.timing.routeDrawingMs,
                    "regionCalculationMs": result.timing.regionCalculationMs,
                    "locationCount": result.locationCount
                ] as [String: Any]
            }
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }

        return jsonString
    }

    // MARK: - Private Helpers

    /// Maximum number of concurrent snapshot operations.
    private static let maxConcurrency = 5

    /// Generates all snapshots in parallel using a TaskGroup with bounded concurrency.
    private func generateAllSnapshots() async {
        // Capture Sendable services before entering the task group to avoid
        // capturing non-Sendable `self` in addTask closures.
        let hkService = healthKitService
        let snapService = snapshotService
        let log = logger

        await withTaskGroup(of: (HKWorkout, SnapshotResult?, Duration?).self) { group in
            var iterator = workouts.makeIterator()
            var inFlight = 0

            // Seed the group with initial tasks up to maxConcurrency
            while inFlight < Self.maxConcurrency, let workout = iterator.next() {
                group.addTask {
                    await Self.processWorkout(workout, healthKitService: hkService, snapshotService: snapService, logger: log)
                }
                inFlight += 1
            }

            // As each task completes, apply results on MainActor and start another
            for await (workout, snapshotResult, locationFetchDuration) in group {
                if let snapshotResult {
                    snapshots[workout] = snapshotResult.image
                    timings[workout] = snapshotResult.timing
                    stats.add(snapshotResult)
                }
                if let locationFetchDuration {
                    fetchStats.addLocationFetchDuration(locationFetchDuration)
                }
                snapshotsCompleted += 1

                // Launch next task
                if let workout = iterator.next() {
                    group.addTask {
                        await Self.processWorkout(workout, healthKitService: hkService, snapshotService: snapService, logger: log)
                    }
                }
            }
        }
    }

    /// Fetches locations and generates a snapshot for a single workout.
    /// Static and nonisolated to avoid capturing MainActor-isolated state — only uses Sendable parameters.
    private static nonisolated func processWorkout(
        _ workout: HKWorkout,
        healthKitService: HealthKitService,
        snapshotService: MapSnapshotService,
        logger: Logger
    ) async -> (HKWorkout, SnapshotResult?, Duration?) {
        do {
            let fetchStart = ContinuousClock.now
            let locations = try await healthKitService.fetchAllLocations(for: workout)
            let fetchDuration = fetchStart.duration(to: .now)

            let result = try await snapshotService.generateSnapshot(for: locations)
            return (workout, result, fetchDuration)
        } catch {
            logger.warning("Snapshot failed for workout \(workout.uuid): \(error.localizedDescription)")
            return (workout, nil, nil)
        }
    }
}
