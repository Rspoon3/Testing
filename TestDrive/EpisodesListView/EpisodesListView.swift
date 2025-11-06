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
            ForEach(viewModel.episodes) { episode in
                NavigationLink {
                    episodeDetailView(for: episode)
                } label: {
                    EpisodeRowView(
                        episode: episode,
                        isDownloaded: viewModel.isDownloaded(episodeID: episode.id),
                        isDownloading: viewModel.isDownloading(episodeID: episode.id),
                        downloadProgress: viewModel.downloadProgress(for: episode.id),
                        onDownloadTap: {
                            viewModel.downloadEpisode(episode)
                        },
                        onPlayTap: nil
                    )
                }
            }
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

    /// Creates an episode detail view for the given episode.
    /// - Parameter episode: The episode to display.
    /// - Returns: An episode detail view.
    private func episodeDetailView(for episode: Episode) -> some View {
        let detailViewModel = EpisodeDetailViewModel(
            episode: episode,
            downloadManager: viewModel.downloadManager,
            playbackManager: viewModel.playbackManager,
            modelContext: modelContext
        )
        return EpisodeDetailView(viewModel: detailViewModel)
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
