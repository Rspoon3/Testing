import Foundation
import SwiftData

/// View model for the episode detail screen.
@Observable
final class EpisodeDetailViewModel {
    /// The episode being displayed.
    let episode: Episode

    /// The downloaded episode if it exists.
    var downloadedEpisode: DownloadedEpisode?

    /// Service for transcription (iOS 26+).
    var transcriptionService: (any TranscriptionServiceProtocol)?

    private let downloadManager: DownloadManager
    let playbackManager: PlaybackManager

    // MARK: - Initializer

    /// Creates a new EpisodeDetailViewModel instance.
    /// - Parameters:
    ///   - episode: The episode to display.
    ///   - downloadManager: Manager for downloading episodes.
    ///   - playbackManager: Manager for audio playback.
    init(
        episode: Episode,
        downloadManager: DownloadManager,
        playbackManager: PlaybackManager
    ) {
        self.episode = episode
        self.downloadManager = downloadManager
        self.playbackManager = playbackManager

        // Initialize transcription service on iOS 26+
        if #available(iOS 26.0, *) {
            self.transcriptionService = TranscriptionService()
        }
    }

    // MARK: - Public Helpers

    /// Loads the downloaded episode if it exists.
    @MainActor
    func loadDownloadedEpisode() {
        downloadedEpisode = downloadManager.getDownloadedEpisode(episodeID: episode.id)
    }

    /// Downloads the episode.
    func downloadEpisode() {
        downloadManager.downloadEpisode(episode)
    }

    /// Plays or resumes the downloaded episode.
    func playEpisode() {
        guard let downloadedEpisode else { return }
        playbackManager.playEpisode(downloadedEpisode)
    }

    /// Toggles play/pause for the episode.
    func togglePlayPause() {
        if isCurrentlyPlaying {
            playbackManager.pause()
        } else {
            playEpisode()
        }
    }

    /// Checks if this episode is currently playing.
    var isCurrentlyPlaying: Bool {
        guard let downloadedEpisode else { return false }
        return playbackManager.currentEpisode?.episodeID == downloadedEpisode.episodeID &&
               playbackManager.isPlaying
    }

    /// Checks if this episode is loaded in the player (playing or paused).
    var isLoadedInPlayer: Bool {
        guard let downloadedEpisode else { return false }
        return playbackManager.currentEpisode?.episodeID == downloadedEpisode.episodeID
    }

    /// Checks if the episode is downloaded.
    var isDownloaded: Bool {
        downloadedEpisode != nil
    }

    /// Gets the download progress for this episode.
    var downloadProgress: Double? {
        downloadManager.downloadProgress[episode.id]
    }

    /// Checks if the episode is currently downloading.
    var isDownloading: Bool {
        downloadManager.activeDownloads.contains(episode.id)
    }

    /// Starts transcription of the downloaded episode (iOS 26+).
    @available(iOS 26.0, *)
    func startTranscription() async {
        guard let downloadedEpisode,
              let service = transcriptionService else { return }

        // Request authorization first
        let authorized = await service.requestAuthorization()
        guard authorized else {
            service.errorMessage = "Speech recognition authorization denied"
            return
        }

        // Get the file URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(downloadedEpisode.localFilePath)

        // Start transcription
        await service.transcribe(fileURL: fileURL)
    }
}
