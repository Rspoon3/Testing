import Foundation

/// Aggregated benchmark statistics for all snapshot operations.
@Observable
final class BenchmarkStats {
    private(set) var results: [SnapshotResult] = []

    /// Total number of completed snapshots.
    var count: Int { results.count }

    /// Total time across all snapshots.
    var totalTimeMs: Double { results.map(\.timing.totalMs).reduce(0, +) }

    /// Average total time per snapshot.
    var averageTotalMs: Double {
        guard !results.isEmpty else { return 0 }
        return totalTimeMs / Double(count)
    }

    /// Minimum total time.
    var minTotalMs: Double { results.map(\.timing.totalMs).min() ?? 0 }

    /// Maximum total time.
    var maxTotalMs: Double { results.map(\.timing.totalMs).max() ?? 0 }

    /// Median total time.
    var medianTotalMs: Double {
        let sorted = results.map(\.timing.totalMs).sorted()
        guard !sorted.isEmpty else { return 0 }
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }

    /// Standard deviation of total times.
    var stdDevTotalMs: Double {
        guard results.count > 1 else { return 0 }
        let mean = averageTotalMs
        let variance = results.map(\.timing.totalMs)
            .map { ($0 - mean) * ($0 - mean) }
            .reduce(0, +) / Double(results.count - 1)
        return variance.squareRoot()
    }

    /// Average snapshot generation time (the MKMapSnapshotter.start() call).
    var averageSnapshotGenerationMs: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.timing.snapshotGenerationMs).reduce(0, +) / Double(count)
    }

    /// Average route drawing time.
    var averageRouteDrawingMs: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.timing.routeDrawingMs).reduce(0, +) / Double(count)
    }

    /// Average region calculation time.
    var averageRegionCalculationMs: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.timing.regionCalculationMs).reduce(0, +) / Double(count)
    }

    /// Total location points processed across all snapshots.
    var totalLocationPoints: Int { results.map(\.locationCount).reduce(0, +) }

    /// Average location points per workout.
    var averageLocationPoints: Double {
        guard !results.isEmpty else { return 0 }
        return Double(totalLocationPoints) / Double(count)
    }

    /// P95 total time.
    var p95TotalMs: Double { percentile(0.95) }

    /// P99 total time.
    var p99TotalMs: Double { percentile(0.99) }

    // MARK: - Public Helpers

    /// Adds a new result to the stats.
    func add(_ result: SnapshotResult) {
        results.append(result)
    }

    /// Resets all collected stats.
    func reset() {
        results.removeAll()
    }

    // MARK: - Private Helpers

    private func percentile(_ p: Double) -> Double {
        let sorted = results.map(\.timing.totalMs).sorted()
        guard !sorted.isEmpty else { return 0 }
        let index = Int(Double(sorted.count - 1) * p)
        return sorted[min(index, sorted.count - 1)]
    }
}
