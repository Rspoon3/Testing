//
//  Episode.swift
//  TestDrive
//

import Foundation

/// Represents a single TV episode for ranking.
struct Episode: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let name: String
    let overview: String?
    let episodeNumber: Int
    let seasonNumber: Int
    let stillPath: String?
    let airDate: String?
    var rank: Int

    /// Full URL for the episode still image.
    var stillURL: URL? {
        guard let stillPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(stillPath)")
    }

    /// Display string like "S01E05".
    var episodeCode: String {
        String(format: "S%02dE%02d", seasonNumber, episodeNumber)
    }

    /// Overview text or empty string if not available.
    var overviewText: String {
        overview ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case stillPath = "still_path"
        case airDate = "air_date"
        case rank
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        episodeNumber = try container.decode(Int.self, forKey: .episodeNumber)
        seasonNumber = try container.decode(Int.self, forKey: .seasonNumber)
        stillPath = try container.decodeIfPresent(String.self, forKey: .stillPath)
        airDate = try container.decodeIfPresent(String.self, forKey: .airDate)
        rank = try container.decodeIfPresent(Int.self, forKey: .rank) ?? 0
    }

    init(
        id: Int,
        name: String,
        overview: String?,
        episodeNumber: Int,
        seasonNumber: Int,
        stillPath: String?,
        airDate: String?,
        rank: Int = 0
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
        self.stillPath = stillPath
        self.airDate = airDate
        self.rank = rank
    }
}
