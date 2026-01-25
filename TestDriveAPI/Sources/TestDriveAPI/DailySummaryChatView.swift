import SwiftUI
import SFSymbols
import MomentumCore
import MomentumNetworking
import MomentumPersistence

/// Displays the AI-generated daily summary message.
public struct DailySummaryChatView: View {
    @State private var viewModel: DailySummaryChatViewModel

    // MARK: - Initializer

    public init(summaryMessage: DailySummaryMessage) {
        _viewModel = State(initialValue: DailySummaryChatViewModel(summaryMessage: summaryMessage))
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SummaryHeader(summaryMessage: viewModel.summaryMessage)

                MessageBubble(
                    message: viewModel.summaryMessage.message,
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
        .navigationTitle(viewModel.summaryMessage.title)
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

                Text(summaryMessage.summaryDate, format: .dateTime.month().day().year().hour().minute())
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

    // MARK: - Private Helpers

    private var iconColor: Color {
        switch viewModel.summaryMessage.summaryType {
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
