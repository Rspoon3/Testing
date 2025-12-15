//
//  Season.swift
//  TestDrive
//

import Foundation

/// Represents a TV season containing episodes.
struct Season: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodeCount: Int?
    let posterPath: String?
    let overview: String?
    var episodes: [Episode]

    /// Full URL for the season poster image.
    var posterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
        case posterPath = "poster_path"
        case overview
        case episodes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        seasonNumber = try container.decode(Int.self, forKey: .seasonNumber)
        episodeCount = try container.decodeIfPresent(Int.self, forKey: .episodeCount)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        episodes = try container.decodeIfPresent([Episode].self, forKey: .episodes) ?? []
    }

    init(
        id: Int,
        name: String,
        seasonNumber: Int,
        episodeCount: Int?,
        posterPath: String?,
        overview: String?,
        episodes: [Episode] = []
    ) {
        self.id = id
        self.name = name
        self.seasonNumber = seasonNumber
        self.episodeCount = episodeCount
        self.posterPath = posterPath
        self.overview = overview
        self.episodes = episodes
    }
}
