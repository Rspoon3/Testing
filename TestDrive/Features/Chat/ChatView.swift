import SwiftUI
import SFSymbols

/// Displays the AI-generated message for a workout.
struct ChatView: View {
    let workoutMessage: WorkoutMessage

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WorkoutSummaryCard(workoutMessage: workoutMessage)

                MessageBubble(message: workoutMessage.message)

                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(workoutMessage.activityName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Private Views

    private func WorkoutSummaryCard(workoutMessage: WorkoutMessage) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(symbol: .figureCooldown)
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text(workoutMessage.activityName)
                    .font(.headline)

                Spacer()

                Text(workoutMessage.workoutDate, style: .date)
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

    private func MessageBubble(message: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(symbol: .sparkles)
                        .font(.caption)
                    Text("Workout Buddy")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)

                Text(message)
                    .font(.body)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
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
                attitude: "encouraging",
                workoutDate: Date()
            )
        )
    }
}
