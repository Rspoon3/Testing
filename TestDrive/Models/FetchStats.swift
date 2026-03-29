import Foundation

/// Timing statistics for the HealthKit fetch phase.
struct FetchStats {
    /// Time to request HealthKit authorization.
    var authorizationDuration: Duration = .zero

    /// Time to fetch and filter workouts with routes.
    var workoutFetchDuration: Duration = .zero

    /// Total number of workouts returned with route data.
    var totalWorkoutsFetched: Int = 0

    /// Per-workout location fetch durations.
    var locationFetchDurations: [Duration] = []

    /// Time to generate all snapshots as a batch.
    var snapshotBatchDuration: Duration = .zero

    /// End-to-end duration from auth to last snapshot.
    var totalDuration: Duration = .zero

    var authorizationMs: Double { authorizationDuration.milliseconds }
    var workoutFetchMs: Double { workoutFetchDuration.milliseconds }
    var snapshotBatchMs: Double { snapshotBatchDuration.milliseconds }
    var totalDurationMs: Double { totalDuration.milliseconds }

    /// Average time to fetch locations per workout.
    var averageLocationFetchMs: Double {
        guard !locationFetchDurations.isEmpty else { return 0 }
        let total = locationFetchDurations.map(\.milliseconds).reduce(0, +)
        return total / Double(locationFetchDurations.count)
    }

    /// Average time per workout for the full pipeline (fetch + snapshot batch / count).
    var averagePerWorkoutMs: Double {
        guard totalWorkoutsFetched > 0 else { return 0 }
        return snapshotBatchMs / Double(totalWorkoutsFetched)
    }

    // MARK: - Public Helpers

    mutating func addLocationFetchDuration(_ duration: Duration) {
        locationFetchDurations.append(duration)
    }
}
