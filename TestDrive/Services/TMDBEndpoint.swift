//
//  TMDBEndpoint.swift
//  TestDrive
//

import Foundation

/// Defines TMDB API endpoints.
enum TMDBEndpoint {
    case searchTV(query: String)
    case showDetails(id: Int)
    case seasonDetails(showId: Int, seasonNumber: Int)

    // MARK: - Public Helpers

    var path: String {
        switch self {
        case .searchTV:
            return "/search/tv"
        case .showDetails(let id):
            return "/tv/\(id)"
        case .seasonDetails(let showId, let seasonNumber):
            return "/tv/\(showId)/season/\(seasonNumber)"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .searchTV(let query):
            return [URLQueryItem(name: "query", value: query)]
        default:
            return []
        }
    }

    /// Builds the complete URL for this endpoint.
    /// - Parameter apiKey: The TMDB API key.
    /// - Returns: The complete URL or nil if construction fails.
    func url(apiKey: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.themoviedb.org"
        components.path = "/3" + path

        var allQueryItems = queryItems
        allQueryItems.append(URLQueryItem(name: "api_key", value: apiKey))
        components.queryItems = allQueryItems

        return components.url
    }
}
