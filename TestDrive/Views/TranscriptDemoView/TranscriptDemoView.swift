import SwiftUI

/// Demo view for downloading transcripts and viewing segments at specific timestamps.
struct TranscriptDemoView: View {
    @State private var viewModel = TranscriptDemoViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                timestampInputSection

                HStack(spacing: 12) {
                    Button {
                        viewModel.fetchSegmentsAtTimestamp()
                    } label: {
                        Text("Fetch Transcript")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading || viewModel.timestampInput.isEmpty)

                    if !viewModel.transcriptText.isEmpty {
                        Button {
                            viewModel.clearTranscript()
                        } label: {
                            Text("Back to Highlights")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                        .frame(maxHeight: .infinity)
                } else if !viewModel.transcriptText.isEmpty {
                    transcriptSection
                } else {
                    highlightsList
                }
            }
            .padding()
            .navigationTitle("Transcript Demo")
            .sheet(isPresented: $viewModel.showingCommentSheet) {
                commentSheet
            }
            .task {
                await viewModel.downloadTranscriptIfNeeded()
                viewModel.loadHighlights()
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


    private var transcriptSection: some View {
        VStack(spacing: 16) {
            // Selectable text view
            SelectableTextView(text: viewModel.transcriptText) { range in
                viewModel.updateSelectionInfo(range: range)
            }
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Selection info panel
            if let selectionInfo = viewModel.selectionInfo {
                selectionInfoPanel(selectionInfo)
            }
        }
    }

    private func selectionInfoPanel(_ info: SelectionInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let first = info.affectedSegments.first,
               let last = info.affectedSegments.last {
                HStack(spacing: 20) {
                    // Start segment
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Segment #\(first.segment.id)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Offset: \(first.startOffset)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // End segment
                    VStack(alignment: .leading, spacing: 4) {
                        Text("End")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Segment #\(last.segment.id)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Offset: \(last.endOffset)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    viewModel.showCommentSheet()
                } label: {
                    Label("Save Highlight", systemImage: "note.text.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
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

    private var highlightsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.highlights.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.quote")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No highlights yet")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Text("Enter a timestamp to view transcript and create highlights")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    ForEach(viewModel.highlights, id: \.id) { highlight in
                        highlightRow(highlight)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func highlightRow(_ highlight: Highlight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatTime(highlight.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    viewModel.deleteHighlight(highlight)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }

            Text(highlight.highlightedText)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let comment = highlight.comment {
                Text(comment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var commentSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Add a comment (optional)", text: $viewModel.commentText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...10)
                    .padding()

                Spacer()
            }
            .navigationTitle("Save Highlight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showingCommentSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveHighlight()
                    }
                }
            }
        }
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
