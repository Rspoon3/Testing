import SwiftUI

/// Displays a list of available audiobooks with their metadata.
struct LibraryView: View {
    @State private var viewModel = LibraryViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading audiobooks...")
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    }
                } else if viewModel.audiobooks.isEmpty {
                    emptyState
                } else {
                    audiobookList
                }
            }
            .navigationTitle("Audiobook Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingDownloadSheet = true
                    } label: {
                        Label("Download", systemImage: "arrow.down.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingDownloadSheet) {
                downloadSheet
            }
            .onAppear {
                viewModel.loadAudiobooks()
            }
        }
    }

    // MARK: - Private Views

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Audiobooks", systemImage: "book.closed")
        } description: {
            Text("No transcript databases found. Download a transcript to get started.")
        }
    }

    private var audiobookList: some View {
        List(viewModel.audiobooks) { audiobook in
            NavigationLink(value: audiobook) {
                AudiobookRow(audiobook: audiobook)
            }
        }
        .navigationDestination(for: Audiobook.self) { audiobook in
            TranscriptDemoView(audiobookId: audiobook.id)
                .onAppear {
                    viewModel.didSelectAudiobook(audiobook.id)
                }
        }
    }

    private func AudiobookRow(audiobook: Audiobook) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(audiobook.id)
                .font(.headline)

            HStack {
                Label("\(audiobook.highlightCount)", systemImage: "highlighter")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if audiobook.lastAccessed != .distantPast {
                    Text(audiobook.lastAccessed, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var downloadSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Enter the audiobook ID to download its transcript.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Audiobook ID", text: $viewModel.audiobookIdInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if viewModel.isDownloading {
                    ProgressView("Downloading transcript...")
                        .frame(maxWidth: .infinity)
                }

                if let downloadError = viewModel.downloadError {
                    Text(downloadError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Download Transcript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelDownload()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Download") {
                        Task {
                            await viewModel.downloadTranscript()
                        }
                    }
                    .disabled(viewModel.audiobookIdInput.isEmpty || viewModel.isDownloading)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    LibraryView()
}
