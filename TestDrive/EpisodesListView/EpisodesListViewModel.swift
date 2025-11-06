import Foundation
import SwiftData

/// View model for the episodes list screen.
@Observable
final class EpisodesListViewModel {
    /// All available episodes from the API.
    var episodes: [Episode] = []

    /// All downloaded episodes from SwiftData.
    var downloadedEpisodes: [DownloadedEpisode] = []

    /// Whether the view is currently loading data.
    var isLoading = false

    /// Error message to display if loading fails.
    var errorMessage: String?

    private let apiService: PodcastAPIService
    private let downloadManager: DownloadManager
    let playbackManager: PlaybackManager
    private let modelContext: ModelContext

    // MARK: - Initializer

    /// Creates a new EpisodesListViewModel instance.
    /// - Parameters:
    ///   - apiService: Service for fetching episodes from the API.
    ///   - downloadManager: Manager for downloading episodes.
    ///   - playbackManager: Manager for audio playback.
    ///   - modelContext: SwiftData model context.
    init(
        apiService: PodcastAPIService,
        downloadManager: DownloadManager,
        playbackManager: PlaybackManager,
        modelContext: ModelContext
    ) {
        self.apiService = apiService
        self.downloadManager = downloadManager
        self.playbackManager = playbackManager
        self.modelContext = modelContext
    }

    // MARK: - Public Helpers

    /// Loads episodes from the API.
    func loadEpisodes() async {
        isLoading = true
        errorMessage = nil

        do {
            episodes = try await apiService.fetchEpisodes()
            await loadDownloadedEpisodes()
        } catch {
            errorMessage = "Failed to load episodes: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Loads downloaded episodes from SwiftData.
    @MainActor
    func loadDownloadedEpisodes() {
        let descriptor = FetchDescriptor<DownloadedEpisode>(
            sortBy: [SortDescriptor(\.publishDate, order: .reverse)]
        )

        do {
            downloadedEpisodes = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading downloaded episodes: \(error)")
        }
    }

    /// Downloads an episode.
    /// - Parameter episode: The episode to download.
    func downloadEpisode(_ episode: Episode) {
        downloadManager.downloadEpisode(episode)
    }

    /// Plays a downloaded episode.
    /// - Parameter episode: The downloaded episode to play.
    func playEpisode(_ episode: DownloadedEpisode) {
        playbackManager.playEpisode(episode)
    }

    /// Deletes a downloaded episode.
    /// - Parameter episode: The episode to delete.
    func deleteEpisode(_ episode: DownloadedEpisode) async {
        await downloadManager.deleteEpisode(episode)
        await loadDownloadedEpisodes()
    }

    /// Checks if an episode is downloaded.
    /// - Parameter episodeID: The episode ID to check.
    /// - Returns: True if downloaded, false otherwise.
    @MainActor
    func isDownloaded(episodeID: Int) -> Bool {
        downloadManager.isDownloaded(episodeID: episodeID)
    }

    /// Gets the downloaded episode for an episode ID.
    /// - Parameter episodeID: The episode ID.
    /// - Returns: The downloaded episode if found, nil otherwise.
    @MainActor
    func getDownloadedEpisode(for episodeID: Int) -> DownloadedEpisode? {
        downloadManager.getDownloadedEpisode(episodeID: episodeID)
    }

    /// Gets the download progress for an episode.
    /// - Parameter episodeID: The episode ID.
    /// - Returns: Download progress from 0.0 to 1.0, or nil if not downloading.
    func downloadProgress(for episodeID: Int) -> Double? {
        downloadManager.downloadProgress[episodeID]
    }

    /// Checks if an episode is currently downloading.
    /// - Parameter episodeID: The episode ID.
    /// - Returns: True if downloading, false otherwise.
    func isDownloading(episodeID: Int) -> Bool {
        downloadManager.activeDownloads.contains(episodeID)
    }
}
