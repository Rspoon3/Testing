import SwiftUI
import SFSymbols

/// A row displaying a single workout message.
struct WorkoutRowView: View {
    let workoutMessage: WorkoutMessage
    let formattedDuration: String
    let formattedCalories: String?
    let formattedDate: String

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "figure.run")
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(workoutMessage.activityName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(formattedDuration)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let calories = formattedCalories {
                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(calories)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(symbol: .bubbleLeftFill)
                .font(.caption)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        WorkoutRowView(
            workoutMessage: WorkoutMessage(
                workoutID: "123",
                activityType: "running",
                activityName: "Running",
                duration: 1920,
                calories: 245,
                distance: 3.2,
                message: "Great run!",
                attitudes: "encouraging",
                workoutDate: Date()
            ),
            formattedDuration: "32 min",
            formattedCalories: "245 cal",
            formattedDate: "Today at 7:30 AM"
        )
    }
}
