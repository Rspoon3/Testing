import SwiftUI
import SFSymbols
import MomentumCore
import MomentumNetworking
import MomentumPersistence

/// Displays the AI-generated message for a weight entry.
public struct WeightChatView: View {
    @State private var viewModel: WeightChatViewModel

    // MARK: - Initializer

    public init(weightMessage: WeightMessage) {
        _viewModel = State(initialValue: WeightChatViewModel(weightMessage: weightMessage))
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WeightSummaryCard(weightMessage: viewModel.weightMessage)

                MessageBubble(
                    message: viewModel.weightMessage.message,
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

                Text(weightMessage.entryDate, format: .dateTime.month().day().year().hour().minute())
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
