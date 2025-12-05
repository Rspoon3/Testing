import SwiftUI

/// A row displaying a daily summary message.
struct DailySummaryRowView: View {
    let summaryMessage: DailySummaryMessage
    let formattedDate: String

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)

                Image(systemName: summaryMessage.symbolName)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(summaryMessage.title)
                    .font(.headline)

                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "text.alignleft")
                .font(.caption)
                .foregroundStyle(iconColor)
        }
        .padding(.vertical, 4)
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

    private var iconBackgroundColor: Color {
        iconColor.opacity(0.15)
    }
}

#Preview {
    List {
        DailySummaryRowView(
            summaryMessage: DailySummaryMessage(
                summaryType: .morning,
                message: "Good morning! You've been crushing it lately.",
                attitudes: "encouraging",
                summaryDate: Date()
            ),
            formattedDate: "Today at 8:00 AM"
        )

        DailySummaryRowView(
            summaryMessage: DailySummaryMessage(
                summaryType: .evening,
                message: "Great day! You completed 2 workouts.",
                attitudes: "encouraging",
                summaryDate: Date()
            ),
            formattedDate: "Today at 9:00 PM"
        )
    }
}
