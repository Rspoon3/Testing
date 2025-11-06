import SwiftUI
import SwiftData

/// Main view displaying the list of podcast episodes.
struct EpisodesListView: View {
    @State private var viewModel: EpisodesListViewModel
    @Environment(\.modelContext) private var modelContext

    // MARK: - Initializer

    /// Creates a new EpisodesListView.
    /// - Parameter viewModel: The view model managing episode data.
    init(viewModel: EpisodesListViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading episodes...")
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    episodesList
                }
            }
            .navigationTitle("Accidental Tech")
            .task {
                await viewModel.loadEpisodes()
            }
            .refreshable {
                await viewModel.loadEpisodes()
            }
            .safeAreaInset(edge: .bottom) {
                PlaybackControlsView(playbackManager: viewModel.playbackManager)
            }
        }
    }

    // MARK: - Private Views

    private var episodesList: some View {
        List {
            if !viewModel.downloadedEpisodes.isEmpty {
                Section("Downloaded") {
                    ForEach(viewModel.downloadedEpisodes, id: \.episodeID) { downloadedEpisode in
                        Button {
                            viewModel.playEpisode(downloadedEpisode)
                        } label: {
                            downloadedEpisodeRow(downloadedEpisode)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteEpisode(downloadedEpisode)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            Section("All Episodes") {
                ForEach(viewModel.episodes) { episode in
                    EpisodeRowView(
                        episode: episode,
                        isDownloaded: viewModel.isDownloaded(episodeID: episode.id),
                        isDownloading: viewModel.isDownloading(episodeID: episode.id),
                        downloadProgress: viewModel.downloadProgress(for: episode.id),
                        onDownloadTap: {
                            viewModel.downloadEpisode(episode)
                        },
                        onPlayTap: {
                            if let downloaded = viewModel.getDownloadedEpisode(for: episode.id) {
                                viewModel.playEpisode(downloaded)
                            }
                        }
                    )
                }
            }
        }
    }

    private func downloadedEpisodeRow(_ downloadedEpisode: DownloadedEpisode) -> some View {
        HStack(spacing: 12) {
            downloadedThumbnail(for: downloadedEpisode)

            VStack(alignment: .leading, spacing: 4) {
                Text(downloadedEpisode.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(formattedDate(downloadedEpisode.publishDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    if downloadedEpisode.playbackPosition > 0 {
                        progressIndicator(for: downloadedEpisode)
                    }

                    Text(formattedDuration(downloadedEpisode.duration))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }

    private func downloadedThumbnail(for episode: DownloadedEpisode) -> some View {
        Group {
            if let artworkURLString = episode.artworkURL,
               let artworkURL = URL(string: artworkURLString) {
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
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func progressIndicator(for episode: DownloadedEpisode) -> some View {
        let progress = episode.playbackPosition / episode.duration

        return HStack(spacing: 4) {
            ProgressView(value: progress)
                .frame(width: 60)

            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Error Loading Episodes", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") {
                Task {
                    await viewModel.loadEpisodes()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Private Helpers

    /// Formats a date for display.
    /// - Parameter date: The date to format.
    /// - Returns: A formatted date string.
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Formats a duration for display.
    /// - Parameter duration: The duration in seconds.
    /// - Returns: A formatted duration string.
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DownloadedEpisode.self, configurations: config)
    let context = container.mainContext

    let apiService = PodcastAPIService()
    let downloadManager = DownloadManager(modelContext: context)
    let playbackManager = PlaybackManager(modelContext: context)

    let viewModel = EpisodesListViewModel(
        apiService: apiService,
        downloadManager: downloadManager,
        playbackManager: playbackManager,
        modelContext: context
    )

    return EpisodesListView(viewModel: viewModel)
        .modelContainer(container)
}
