//
//  TMDBService.swift
//  TestDrive
//

import Foundation

/// Errors that can occur during TMDB API operations.
enum TMDBError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        }
    }
}

/// Handles all TMDB API communication.
actor TMDBService {
    private let apiKey: String
    private let decoder: JSONDecoder
    private let session: URLSession

    // MARK: - Initializer

    init(apiKey: String = Secrets.tmdbAPIKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - Public Helpers

    /// Searches for TV shows by name.
    /// - Parameter query: The search query.
    /// - Returns: Array of matching TV shows.
    func searchShows(query: String) async throws -> [TVShow] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let endpoint = TMDBEndpoint.searchTV(query: query)
        let response: TMDBTVShowSearchResponse = try await fetch(endpoint: endpoint)
        return response.results
    }

    /// Gets full show details including season list.
    /// - Parameter id: The TMDB show ID.
    /// - Returns: The TV show with season information.
    func getShowDetails(id: Int) async throws -> TVShow {
        let endpoint = TMDBEndpoint.showDetails(id: id)
        let response: TMDBShowDetailsResponse = try await fetch(endpoint: endpoint)
        return response.toTVShow()
    }

    /// Gets all episodes for a specific season.
    /// - Parameters:
    ///   - showId: The TMDB show ID.
    ///   - seasonNumber: The season number.
    /// - Returns: Array of episodes in the season.
    func getSeasonEpisodes(showId: Int, seasonNumber: Int) async throws -> [Episode] {
        let endpoint = TMDBEndpoint.seasonDetails(showId: showId, seasonNumber: seasonNumber)
        let response: TMDBSeasonResponse = try await fetch(endpoint: endpoint)
        return response.episodes
    }

    /// Fetches all episodes from all seasons of a show.
    /// - Parameter show: The TV show.
    /// - Returns: Array of all episodes across all seasons.
    func getAllEpisodes(for show: TVShow) async throws -> [Episode] {
        // First get show details to get accurate season list
        let showDetails = try await getShowDetails(id: show.id)

        // Filter to regular seasons (exclude specials which are season 0)
        let regularSeasons = showDetails.seasons.filter { $0.seasonNumber > 0 }

        // Fetch episodes for all seasons concurrently
        var allEpisodes: [Episode] = []

        try await withThrowingTaskGroup(of: (Int, [Episode]).self) { group in
            for season in regularSeasons {
                group.addTask {
                    let episodes = try await self.getSeasonEpisodes(
                        showId: show.id,
                        seasonNumber: season.seasonNumber
                    )
                    return (season.seasonNumber, episodes)
                }
            }

            // Collect results
            var episodesBySeasons: [(Int, [Episode])] = []
            for try await result in group {
                episodesBySeasons.append(result)
            }

            // Sort by season number and flatten
            episodesBySeasons.sort { $0.0 < $1.0 }
            allEpisodes = episodesBySeasons.flatMap(\.1)
        }

        return allEpisodes
    }

    // MARK: - Private Helpers

    private func fetch<T: Codable>(endpoint: TMDBEndpoint) async throws -> T {
        guard let url = endpoint.url(apiKey: apiKey) else {
            throw TMDBError.invalidURL
        }

        do {
            let (data, _) = try await session.data(from: url)
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            print("🔴 Decoding error: \(error)")
            if case .keyNotFound(let key, let context) = error {
                print("🔴 Missing key: '\(key.stringValue)' in \(context.codingPath.map(\.stringValue))")
            } else if case .typeMismatch(let type, let context) = error {
                print("🔴 Type mismatch: expected \(type) at \(context.codingPath.map(\.stringValue))")
            } else if case .valueNotFound(let type, let context) = error {
                print("🔴 Value not found: \(type) at \(context.codingPath.map(\.stringValue))")
            }
            throw TMDBError.decodingError(error)
        } catch {
            throw TMDBError.networkError(error)
        }
    }
}
