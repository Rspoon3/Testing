import SwiftUI
import SFSymbols

/// Displays the AI-generated daily summary message.
struct DailySummaryChatView: View {
    let summaryMessage: DailySummaryMessage

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SummaryHeader(summaryMessage: summaryMessage)

                MessageBubble(message: summaryMessage.message)

                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(summaryMessage.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Private Views

    private func SummaryHeader(summaryMessage: DailySummaryMessage) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: summaryMessage.symbolName)
                    .font(.title2)
                    .foregroundStyle(iconColor)

                Text(summaryMessage.title)
                    .font(.headline)

                Spacer()

                Text(summaryMessage.summaryDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Generated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summaryMessage.createdAt, style: .time)
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()
            }
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

    // MARK: - Private Helpers

    private var iconColor: Color {
        switch summaryMessage.summaryType {
        case .morning:
            return .orange
        case .evening:
            return .indigo
        }
    }
}

#Preview {
    NavigationStack {
        DailySummaryChatView(
            summaryMessage: DailySummaryMessage(
                summaryType: .morning,
                message: "Good morning! You've been on a roll lately - 5 workouts in the past week. Today's a great day to keep that momentum going. Remember, consistency beats intensity every time.",
                attitudes: "encouraging",
                summaryDate: Date()
            )
        )
    }
}
