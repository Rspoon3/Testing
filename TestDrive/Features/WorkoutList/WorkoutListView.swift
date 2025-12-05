import SwiftUI
import SFSymbols

/// Main screen showing the user's workout history.
struct WorkoutListView: View {
    @Bindable var coordinator: AppCoordinator
    @State private var viewModel = WorkoutListViewModel()
    @State private var showSettings = false
    @State private var navigationPath = NavigationPath()

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
            .onChange(of: coordinator.selectedWorkoutMessage) { _, newValue in
                if let message = newValue {
                    navigationPath.append(message)
                    coordinator.selectedWorkoutMessage = nil
                }
            }
        }
    }

    // MARK: - Private Views

    private var workoutList: some View {
        List(viewModel.workouts, id: \.uuid) { workout in
            if let message = viewModel.message(for: workout) {
                NavigationLink(value: message) {
                    WorkoutRowView(
                        workout: workout,
                        formattedDuration: viewModel.formattedDuration(workout),
                        formattedCalories: viewModel.formattedCalories(workout),
                        formattedDate: viewModel.formattedDate(workout),
                        hasMessage: true
                    )
                }
            } else {
                WorkoutRowView(
                    workout: workout,
                    formattedDuration: viewModel.formattedDuration(workout),
                    formattedCalories: viewModel.formattedCalories(workout),
                    formattedDate: viewModel.formattedDate(workout),
                    hasMessage: false
                )
            }
        }
        .navigationDestination(for: WorkoutMessage.self) { message in
            ChatView(workoutMessage: message)
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
    WorkoutListView(coordinator: AppCoordinator())
}
