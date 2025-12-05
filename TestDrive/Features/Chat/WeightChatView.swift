import SwiftUI
import SFSymbols

/// Displays the AI-generated message for a weight entry.
struct WeightChatView: View {
    let weightMessage: WeightMessage

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WeightSummaryCard(weightMessage: weightMessage)

                MessageBubble(message: weightMessage.message)

                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Private Views

    private func WeightSummaryCard(weightMessage: WeightMessage) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(symbol: .scalemass)
                    .font(.title2)
                    .foregroundStyle(.green)

                Text("Weight Entry")
                    .font(.headline)

                Spacer()

                Text(weightMessage.entryDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(weightMessage.formattedWeight)
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()
            }

            Text(weightMessage.weightEntryID)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospaced()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        WeightChatView(
            weightMessage: WeightMessage(
                weightEntryID: "123",
                weightInPounds: 175.5,
                message: "Nice! You're down half a pound from yesterday. Those workouts are paying off!",
                attitudes: "encouraging",
                entryDate: Date()
            )
        )
    }
}
