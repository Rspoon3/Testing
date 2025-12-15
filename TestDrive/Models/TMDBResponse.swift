//
//  TMDBResponse.swift
//  TestDrive
//

import Foundation

/// Wrapper for TMDB TV show search results.
struct TMDBTVShowSearchResponse: Codable {
    let page: Int
    let results: [TVShow]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

/// Response for TV show details including seasons.
struct TMDBShowDetailsResponse: Codable, Sendable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let numberOfSeasons: Int?
    let seasons: [Season]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case numberOfSeasons = "number_of_seasons"
        case seasons
    }

    /// Converts to TVShow model.
    func toTVShow() -> TVShow {
        TVShow(
            id: id,
            name: name,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            firstAirDate: firstAirDate,
            numberOfSeasons: numberOfSeasons,
            seasons: seasons
        )
    }
}

/// Response for season details including episodes.
struct TMDBSeasonResponse: Codable, Sendable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodes: [Episode]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case seasonNumber = "season_number"
        case episodes
    }
}
