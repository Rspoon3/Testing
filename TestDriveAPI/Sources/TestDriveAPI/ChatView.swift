import SwiftUI
import SFSymbols
import MomentumCore
import MomentumNetworking
import MomentumPersistence

/// Displays the AI-generated message for a workout.
public struct ChatView: View {
    @State private var viewModel: ChatViewModel

    // MARK: - Initializer

    public init(workoutMessage: WorkoutMessage) {
        _viewModel = State(initialValue: ChatViewModel(workoutMessage: workoutMessage))
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WorkoutSummaryCard(workoutMessage: viewModel.workoutMessage)

                MessageBubble(
                    message: viewModel.workoutMessage.message,
                    isRegenerating: viewModel.isRegenerating
                )

                #if DEBUG
                RegenerateButton(
                    isRegenerating: viewModel.isRegenerating,
                    errorMessage: viewModel.errorMessage
                ) {
                    Task {
                        await viewModel.regenerateMessage()
                    }
                }
                #endif

                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.workoutMessage.activityName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Private Views

    private func WorkoutSummaryCard(workoutMessage: WorkoutMessage) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(symbol: workoutMessage.symbol)
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text(workoutMessage.activityName)
                    .font(.headline)

                Spacer()

                Text(workoutMessage.workoutDate, format: .dateTime.month().day().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                StatItem(label: "Duration", value: workoutMessage.formattedDuration)

                if let calories = workoutMessage.formattedCalories {
                    StatItem(label: "Calories", value: calories)
                }

                if let distance = workoutMessage.formattedDistance {
                    StatItem(label: "Distance", value: distance)
                }

                Spacer()
            }

        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func StatItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    private func MessageBubble(message: String, isRegenerating: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(symbol: .sparkles)
                        .font(.caption)
                    Text("Momentum")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)

                if isRegenerating {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Generating new message...")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(message)
                        .font(.body)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
    }

    private func RegenerateButton(
        isRegenerating: Bool,
        errorMessage: String?,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            Button {
                action()
            } label: {
                HStack {
                    if isRegenerating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(symbol: .arrowClockwise)
                    }
                    Text(isRegenerating ? "Regenerating..." : "Regenerate Message")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isRegenerating)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Text("Using: \(UserPreferences.shared.selectedAIProvider.displayName)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(
            workoutMessage: WorkoutMessage(
                workoutID: "123",
                activityType: "running",
                activityName: "Running",
                duration: 1800,
                calories: 250,
                distance: 3.2,
                message: "Great job on that 30-minute run! You're building some serious endurance there.",
                attitudes: "encouraging",
                workoutDate: Date()
            )
        )
    }
}
