import SwiftUI
import SFSymbols

/// Main screen showing the user's health history (workouts and weight).
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
                    ProgressView("Loading...")
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.healthEvents.isEmpty {
                    emptyStateView
                } else {
                    healthEventsList
                }
            }
            .navigationTitle("Activity")
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
                await viewModel.fetchHealthEvents()
            }
            .refreshable {
                await viewModel.fetchHealthEvents()
            }
            .onChange(of: coordinator.selectedWorkoutMessage) { _, newValue in
                if let message = newValue {
                    navigationPath.append(HealthEvent.workout(message))
                    coordinator.selectedWorkoutMessage = nil
                }
            }
            .onChange(of: coordinator.selectedWeightMessage) { _, newValue in
                if let message = newValue {
                    navigationPath.append(HealthEvent.weight(message))
                    coordinator.selectedWeightMessage = nil
                }
            }
        }
    }

    // MARK: - Private Views

    private var healthEventsList: some View {
        List(viewModel.healthEvents) { event in
            NavigationLink(value: event) {
                switch event {
                case .workout(let message):
                    WorkoutRowView(
                        workoutMessage: message,
                        formattedDuration: viewModel.formattedDuration(message),
                        formattedCalories: viewModel.formattedCalories(message),
                        formattedDate: viewModel.formattedDate(message.workoutDate)
                    )
                case .weight(let message):
                    WeightRowView(
                        weightMessage: message,
                        formattedDate: viewModel.formattedDate(message.entryDate)
                    )
                }
            }
        }
        .navigationDestination(for: HealthEvent.self) { event in
            switch event {
            case .workout(let message):
                ChatView(workoutMessage: message)
            case .weight(let message):
                WeightChatView(weightMessage: message)
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Activity Yet",
            systemImage: "heart.text.square",
            description: Text("Complete a workout or log your weight to see it here")
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
