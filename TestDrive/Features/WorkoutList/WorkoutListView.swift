import SwiftUI
import SFSymbols

/// Main screen showing the user's workout history.
struct WorkoutListView: View {
    @State private var viewModel = WorkoutListViewModel()
    @State private var showSettings = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading workouts...")
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.workouts.isEmpty {
                    emptyStateView
                } else {
                    workoutList
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(symbol: .gearshape)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .task {
                await viewModel.fetchWorkouts()
            }
            .refreshable {
                await viewModel.fetchWorkouts()
            }
        }
    }

    // MARK: - Private Views

    private var workoutList: some View {
        List(viewModel.workouts, id: \.uuid) { workout in
            WorkoutRowView(
                workout: workout,
                formattedDuration: viewModel.formattedDuration(workout),
                formattedCalories: viewModel.formattedCalories(workout),
                formattedDate: viewModel.formattedDate(workout)
            )
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Workouts Yet",
            systemImage: "figure.run",
            description: Text("Complete a workout and it will appear here")
        )
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView(
            "Unable to Load",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }
}

#Preview {
    WorkoutListView()
}
