import Foundation

/// Service for fetching podcast episodes from the iTunes Search API.
@Observable
final class PodcastAPIService {
    // The Accidental Tech Podcast ID on iTunes
    private let podcastID = "617416468"
    private let baseURL = "https://itunes.apple.com/lookup"

    /// Response structure from the iTunes Search API.
    private struct APIResponse: Codable {
        let results: [Episode]
    }

    // MARK: - Public Helpers

    /// Fetches episodes for The Accidental Tech Podcast.
    /// - Parameter limit: Maximum number of episodes to fetch (default: 200).
    /// - Returns: An array of Episode objects sorted by publish date (newest first).
    /// - Throws: An error if the network request fails or JSON parsing fails.
    func fetchEpisodes(limit: Int = 50) async throws -> [Episode] {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "id", value: podcastID),
            URLQueryItem(name: "entity", value: "podcastEpisode"),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)

        // Filter out the podcast itself (first result) and return only valid episodes
        let episodes = apiResponse.results.filter { $0.duration > 0 && $0.audioURL != nil }

        // Sort by publish date, newest first
        return episodes.sorted { $0.publishDate > $1.publishDate }
    }
}
