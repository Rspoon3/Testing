import Foundation
import SwiftData

/// Represents a downloaded podcast episode stored locally.
@Model
final class DownloadedEpisode {
    /// Unique identifier matching the Episode ID from the API.
    @Attribute(.unique) var episodeID: Int

    /// The episode title.
    var title: String

    /// The episode description or show notes.
    var episodeDescription: String

    /// Duration of the episode in seconds.
    var duration: TimeInterval

    /// Local file path where the audio file is stored.
    var localFilePath: String

    /// URL to the episode artwork.
    var artworkURL: String?

    /// The date the episode was published.
    var publishDate: Date

    /// Current playback position in seconds.
    var playbackPosition: TimeInterval

    /// Whether the episode has been fully listened to.
    var isCompleted: Bool

    /// The transcription text if the episode has been transcribed.
    var transcript: String?

    // MARK: - Initializer

    /// Creates a new DownloadedEpisode instance.
    /// - Parameters:
    ///   - episodeID: Unique identifier matching the Episode ID from the API.
    ///   - title: The episode title.
    ///   - episodeDescription: The episode description or show notes.
    ///   - duration: Duration of the episode in seconds.
    ///   - localFilePath: Local file path where the audio file is stored.
    ///   - artworkURL: Optional URL string to the episode artwork.
    ///   - publishDate: The date the episode was published.
    ///   - playbackPosition: Current playback position in seconds (default: 0).
    ///   - isCompleted: Whether the episode has been fully listened to (default: false).
    init(
        episodeID: Int,
        title: String,
        episodeDescription: String,
        duration: TimeInterval,
        localFilePath: String,
        artworkURL: String? = nil,
        publishDate: Date,
        playbackPosition: TimeInterval = 0,
        isCompleted: Bool = false
    ) {
        self.episodeID = episodeID
        self.title = title
        self.episodeDescription = episodeDescription
        self.duration = duration
        self.localFilePath = localFilePath
        self.artworkURL = artworkURL
        self.publishDate = publishDate
        self.playbackPosition = playbackPosition
        self.isCompleted = isCompleted
    }
}
