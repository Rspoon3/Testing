import Foundation

/// Represents a podcast episode from The Accidental Tech Podcast.
struct Episode: Identifiable, Codable {
    /// Unique identifier for the episode.
    let id: Int

    /// The episode title.
    let title: String

    /// The episode description or show notes.
    let description: String

    /// Duration of the episode in seconds.
    let duration: TimeInterval

    /// URL to the audio file.
    let audioURL: URL?

    /// URL to the episode artwork.
    let artworkURL: URL?

    /// The date the episode was published.
    let publishDate: Date

    // MARK: - Codable Keys

    enum CodingKeys: String, CodingKey {
        case id = "trackId"
        case title = "trackName"
        case description
        case duration = "trackTimeMillis"
        case audioURL = "episodeUrl"
        case artworkURL = "artworkUrl600"
        case publishDate = "releaseDate"
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""

        // Convert milliseconds to seconds
        let durationMillis = try container.decode(Int.self, forKey: .duration)
        duration = TimeInterval(durationMillis) / 1000.0

        if let audioURLString = try container.decodeIfPresent(String.self, forKey: .audioURL) {
            audioURL = URL(string: audioURLString)
        } else {
            audioURL = nil
        }

        if let artworkURLString = try container.decodeIfPresent(String.self, forKey: .artworkURL) {
            artworkURL = URL(string: artworkURLString)
        } else {
            artworkURL = nil
        }

        let dateString = try container.decode(String.self, forKey: .publishDate)
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .publishDate,
                in: container,
                debugDescription: "Invalid date format"
            )
        }
        publishDate = date
    }

    // MARK: - Initializer

    /// Creates a new Episode instance.
    /// - Parameters:
    ///   - id: Unique identifier for the episode.
    ///   - title: The episode title.
    ///   - description: The episode description or show notes.
    ///   - duration: Duration of the episode in seconds.
    ///   - audioURL: Optional URL to the audio file.
    ///   - artworkURL: Optional URL to the episode artwork.
    ///   - publishDate: The date the episode was published.
    init(
        id: Int,
        title: String,
        description: String,
        duration: TimeInterval,
        audioURL: URL? = nil,
        artworkURL: URL? = nil,
        publishDate: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.duration = duration
        self.audioURL = audioURL
        self.artworkURL = artworkURL
        self.publishDate = publishDate
    }
}
