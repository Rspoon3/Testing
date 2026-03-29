import SwiftUI
import HealthKit

/// Displays a grid of workout map snapshots with benchmark statistics.
struct WorkoutMapView: View {
    @State private var viewModel = WorkoutMapViewModel()
    @State private var showShareSheet = false
    @State private var exportText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage, viewModel.workouts.isEmpty {
                        errorView(error)
                    } else {
                        if viewModel.fetchStats.totalWorkoutsFetched > 0 {
                            fetchStatsSection
                        }

                        if viewModel.stats.count > 0 {
                            statsSection
                        }

                        if viewModel.isGeneratingSnapshots {
                            progressView
                        }

                        snapshotGrid
                    }
                }
                .padding()
            }
            .navigationTitle("Workout Snapshots")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: exportText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(viewModel.stats.count == 0 || viewModel.isGeneratingSnapshots)
                    .onChange(of: viewModel.isGeneratingSnapshots) {
                        if !viewModel.isGeneratingSnapshots, viewModel.stats.count > 0 {
                            exportText = viewModel.exportBenchmarkJSON()
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadWorkouts() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading || viewModel.isGeneratingSnapshots)
                }
            }
            .task {
                await viewModel.loadWorkouts()
            }
        }
    }

    // MARK: - Private Views

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Fetching workouts...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private var progressView: some View {
        VStack(spacing: 8) {
            ProgressView(
                value: Double(viewModel.snapshotsCompleted),
                total: Double(max(viewModel.snapshotsTotal, 1))
            )
            Text("Generating snapshots \(viewModel.snapshotsCompleted)/\(viewModel.snapshotsTotal)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var fetchStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fetch Stats")
                .font(.headline)

            let fetch = viewModel.fetchStats

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                StatCard(title: "Authorization", value: String(format: "%.1f ms", fetch.authorizationMs))
                StatCard(title: "Workout Fetch", value: String(format: "%.1f ms", fetch.workoutFetchMs))
                StatCard(title: "Workouts Found", value: "\(fetch.totalWorkoutsFetched)")
                StatCard(title: "Avg Loc Fetch", value: String(format: "%.1f ms", fetch.averageLocationFetchMs))
                StatCard(title: "Snapshot Batch", value: String(format: "%.1f ms", fetch.snapshotBatchMs))
                StatCard(title: "Avg Per Workout", value: String(format: "%.1f ms", fetch.averagePerWorkoutMs))
                StatCard(title: "End-to-End", value: String(format: "%.1f ms", fetch.totalDurationMs))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benchmark Stats")
                .font(.headline)

            let stats = viewModel.stats

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                StatCard(title: "Count", value: "\(stats.count)")
                StatCard(title: "Avg Total", value: String(format: "%.1f ms", stats.averageTotalMs))
                StatCard(title: "Min", value: String(format: "%.1f ms", stats.minTotalMs))
                StatCard(title: "Max", value: String(format: "%.1f ms", stats.maxTotalMs))
                StatCard(title: "Median", value: String(format: "%.1f ms", stats.medianTotalMs))
                StatCard(title: "Std Dev", value: String(format: "%.1f ms", stats.stdDevTotalMs))
                StatCard(title: "P95", value: String(format: "%.1f ms", stats.p95TotalMs))
                StatCard(title: "P99", value: String(format: "%.1f ms", stats.p99TotalMs))
                StatCard(title: "Avg Snapshot", value: String(format: "%.1f ms", stats.averageSnapshotGenerationMs))
                StatCard(title: "Avg Drawing", value: String(format: "%.1f ms", stats.averageRouteDrawingMs))
                StatCard(title: "Total Points", value: "\(stats.totalLocationPoints)")
                StatCard(title: "Avg Points", value: String(format: "%.0f", stats.averageLocationPoints))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var snapshotGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(viewModel.workouts, id: \.uuid) { workout in
                snapshotCell(for: workout)
            }
        }
    }

    private func snapshotCell(for workout: HKWorkout) -> some View {
        VStack(spacing: 4) {
            if let image = viewModel.snapshots[workout] {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        ProgressView()
                    }
            }

            Text(workout.workoutActivityType.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let timing = viewModel.timings[workout] {
                Text(String(format: "%.0f ms", timing.totalMs))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .fontDesign(.monospaced)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - HKWorkoutActivityType Extension

extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running: "Running"
        case .walking: "Walking"
        case .cycling: "Cycling"
        case .hiking: "Hiking"
        case .swimming: "Swimming"
        case .yoga: "Yoga"
        case .functionalStrengthTraining: "Strength"
        case .traditionalStrengthTraining: "Strength"
        case .crossTraining: "Cross Training"
        case .elliptical: "Elliptical"
        case .rowing: "Rowing"
        case .stairClimbing: "Stairs"
        case .highIntensityIntervalTraining: "HIIT"
        case .dance: "Dance"
        case .cooldown: "Cooldown"
        case .paddleSports: "Paddle Sports"
        case .surfingSports: "Surfing"
        case .snowSports: "Snow Sports"
        case .golf: "Golf"
        case .tennis: "Tennis"
        case .soccer: "Soccer"
        case .basketball: "Basketball"
        default: "Workout"
        }
    }
}

#Preview {
    WorkoutMapView()
}
