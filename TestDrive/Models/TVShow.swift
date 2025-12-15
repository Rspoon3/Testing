//
//  TVShow.swift
//  TestDrive
//

import Foundation

/// Represents a TV show from TMDB.
struct TVShow: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let numberOfSeasons: Int?
    var seasons: [Season]

    /// Full URL for the show poster image.
    var posterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }

    /// Full URL for the show backdrop image.
    var backdropURL: URL? {
        guard let backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(backdropPath)")
    }

    /// Year extracted from first air date.
    var yearString: String? {
        guard let firstAirDate, !firstAirDate.isEmpty else { return nil }
        return String(firstAirDate.prefix(4))
    }

    /// Overview text or empty string if not available.
    var overviewText: String {
        overview ?? ""
    }

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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        firstAirDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate)
        numberOfSeasons = try container.decodeIfPresent(Int.self, forKey: .numberOfSeasons)
        seasons = try container.decodeIfPresent([Season].self, forKey: .seasons) ?? []
    }

    init(
        id: Int,
        name: String,
        overview: String?,
        posterPath: String?,
        backdropPath: String?,
        firstAirDate: String?,
        numberOfSeasons: Int?,
        seasons: [Season] = []
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.firstAirDate = firstAirDate
        self.numberOfSeasons = numberOfSeasons
        self.seasons = seasons
    }
}
