import SwiftUI

/// Demo view for downloading transcripts and viewing segments at specific timestamps.
struct TranscriptDemoView: View {
    @State private var viewModel = TranscriptDemoViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                timestampInputSection
                fetchButton
                contentSection
            }
            .padding()
            .navigationTitle("Transcript Demo")
            .task {
                await viewModel.downloadTranscriptIfNeeded()
            }
        }
    }

    // MARK: - Private Views

    private var timestampInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Audiobook ID")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(viewModel.audiobookId)
                .font(.footnote)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("Timestamp (seconds)")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Enter timestamp", text: $viewModel.timestampInput)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
        }
    }

    private var fetchButton: some View {
        Button {
            viewModel.fetchSegmentsAtTimestamp()
        } label: {
            Text("Fetch Transcript")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isLoading || viewModel.timestampInput.isEmpty)
    }

    private var contentSection: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else if !viewModel.segments.isEmpty {
                segmentsList
            } else {
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.quote")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Enter a timestamp to view transcript segments")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var segmentsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.segments, id: \.id) { segment in
                    segmentRow(segment)
                }
            }
            .padding(.vertical)
        }
    }

    private func segmentRow(_ segment: TranscriptSegment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatTime(segment.startTimeInSeconds))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatTime(segment.endTimeInSeconds))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(segment.text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Private Helpers

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    TranscriptDemoView()
}
