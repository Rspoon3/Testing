import SwiftUI
import SwiftData

/// Detailed view for a single podcast episode.
struct EpisodeDetailView: View {
    @State private var viewModel: EpisodeDetailViewModel
    @State private var showTranscript = false

    // MARK: - Initializer

    /// Creates a new EpisodeDetailView.
    /// - Parameter viewModel: The view model managing episode data.
    init(viewModel: EpisodeDetailViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                artwork

                VStack(alignment: .leading, spacing: 16) {
                    Text(viewModel.episode.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 16) {
                        Label(formattedDate, systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Label(formattedDuration, systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if !viewModel.episode.description.isEmpty {
                        Text(viewModel.episode.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                actionButton
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isDownloaded {
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showTranscript = true
                        } label: {
                            Label("Transcribe", systemImage: "doc.text")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showTranscript) {
            if #available(iOS 26.0, *) {
                transcriptView
            }
        }
        .safeAreaInset(edge: .bottom) {
            PlaybackControlsView(playbackManager: viewModel.playbackManager)
        }
        .task {
            viewModel.loadDownloadedEpisode()
        }
        .onChange(of: viewModel.isDownloading) { oldValue, newValue in
            if oldValue && !newValue {
                // Download just finished, refresh the downloaded episode
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    viewModel.loadDownloadedEpisode()
                }
            }
        }
    }

    // MARK: - Private Views

    @available(iOS 26.0, *)
    private var transcriptView: some View {
        NavigationStack {
            if let service = viewModel.transcriptionService {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if service.isInstallingModel {
                            VStack(spacing: 12) {
                                HStack {
                                    ProgressView()
                                    Text("Installing speech model...")
                                        .font(.headline)
                                }

                                ProgressView(value: service.modelInstallationProgress) {
                                    Text("Downloading")
                                        .font(.subheadline)
                                }
                                .tint(.blue)

                                Text("\(Int(service.modelInstallationProgress * 100))% complete")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                        } else if service.isTranscribing {
                            HStack {
                                ProgressView()
                                Text("Transcribing...")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                        }

                        if let errorMessage = service.errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .padding()
                        }

                        if !service.transcriptionText.isEmpty {
                            Text(service.transcriptionText)
                                .font(.body)
                                .padding()
                        } else if !service.isTranscribing && !service.isInstallingModel {
                            ContentUnavailableView(
                                "No Transcript",
                                systemImage: "doc.text",
                                description: Text("Tap the button below to start transcription")
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationTitle("Transcript")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            showTranscript = false
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task {
                                await viewModel.startTranscription()
                            }
                        } label: {
                            Label("Start", systemImage: "play.circle")
                        }
                        .disabled(service.isTranscribing || service.isInstallingModel)
                    }
                }
            }
        }
    }

    private var artwork: some View {
        Group {
            if let artworkURL = viewModel.episode.artworkURL {
                AsyncImage(url: artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                }
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.3))
            }
        }
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
    }

    @ViewBuilder
    private var actionButton: some View {
        if viewModel.isDownloaded {
            playButton
        } else if viewModel.isDownloading, let progress = viewModel.downloadProgress {
            downloadProgressView(progress: progress)
        } else {
            downloadButton
        }
    }

    private var playButton: some View {
        Button {
            if viewModel.isCurrentlyPlaying {
                viewModel.playbackManager.pause()
            } else {
                viewModel.playEpisode()
            }
        } label: {
            HStack {
                Image(systemName: viewModel.isCurrentlyPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)

                Text(viewModel.isCurrentlyPlaying ? "Pause" : "Play Episode")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var downloadButton: some View {
        Button {
            viewModel.downloadEpisode()
        } label: {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title)

                Text("Download Episode")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func downloadProgressView(progress: Double) -> some View {
        VStack(spacing: 12) {
            ProgressView(value: progress) {
                Text("Downloading...")
                    .font(.headline)
            }
            .tint(.blue)

            Text("\(Int(progress * 100))% complete")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Private Helpers

    /// Formats the episode publish date for display.
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: viewModel.episode.publishDate)
    }

    /// Formats the episode duration for display.
    private var formattedDuration: String {
        let hours = Int(viewModel.episode.duration) / 3600
        let minutes = Int(viewModel.episode.duration) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    NavigationStack {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: DownloadedEpisode.self, configurations: config)
        let context = container.mainContext

        let downloadManager = DownloadManager(modelContext: context)
        let playbackManager = PlaybackManager(modelContext: context)

        let episode = Episode(
            id: 1,
            title: "663: Defending the Honor of The Cheesecake Factory",
            description: "Casey is back from vacation and eager to discuss Apple Intelligence, whether we\'ve kept up with our photos libraries, and lots of discussion about AVP use cases.",
            duration: 7265,
            audioURL: URL(string: "https://example.com/episode.mp3"),
            artworkURL: URL(string: "https://example.com/artwork.jpg"),
            publishDate: Date()
        )

        let viewModel = EpisodeDetailViewModel(
            episode: episode,
            downloadManager: downloadManager,
            playbackManager: playbackManager
        )

        return EpisodeDetailView(viewModel: viewModel)
            .modelContainer(container)
    }
}
