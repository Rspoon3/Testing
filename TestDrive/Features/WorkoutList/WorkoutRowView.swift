import SwiftUI
import HealthKit
import SFSymbols

/// A row displaying a single workout.
struct WorkoutRowView: View {
    let workout: HKWorkout
    let formattedDuration: String
    let formattedCalories: String?
    let formattedDate: String
    var hasMessage: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            workoutIcon

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(workout.workoutActivityType.displayName)
                        .font(.headline)

                    if hasMessage {
                        Image(symbol: .sparkles)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                HStack(spacing: 12) {
                    Label(formattedDuration, symbol: .clock)

                    if let calories = formattedCalories {
                        Label(calories, symbol: .flameFill)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Private Views

    private var workoutIcon: some View {
        Image(symbol: workout.workoutActivityType.symbol)
            .font(.title2)
            .foregroundStyle(.blue)
            .frame(width: 44, height: 44)
            .background(Color.accentColor.opacity(0.1))
            .clipShape(Circle())
    }
}

#Preview {
    List {
        WorkoutRowView(
            workout: HKWorkout(activityType: .running, start: Date(), end: Date()),
            formattedDuration: "32 min",
            formattedCalories: "245 cal",
            formattedDate: "Today at 7:30 AM"
        )
    }
}
