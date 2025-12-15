//
//  RankingSession.swift
//  TestDrive
//

import Foundation

/// Persisted state for a ranking session.
struct RankingSession: Identifiable, Codable, Sendable, Hashable, Equatable {
    let id: UUID
    let showId: Int
    let showName: String
    let showPosterPath: String?
    let createdAt: Date
    var lastModified: Date

    /// Original shuffled order of episodes for deterministic replay.
    var initialSeeding: [Episode]

    /// User selections in order (true = left won, false = right won).
    var comparisonResults: [Bool]

    /// Current position in the comparison sequence.
    var currentComparisonIndex: Int

    /// Whether the ranking is complete.
    var isComplete: Bool

    /// The winning episode after ranking completes.
    var winnerEpisode: Episode?

    /// Progress as percentage (0.0 - 1.0).
    var progress: Double {
        guard !initialSeeding.isEmpty else { return 0 }
        let totalComparisons = initialSeeding.count - 1
        guard totalComparisons > 0 else { return 1.0 }
        return Double(comparisonResults.count) / Double(totalComparisons)
    }

    /// Full URL for the show poster image.
    var showPosterURL: URL? {
        guard let showPosterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(showPosterPath)")
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        showId: Int,
        showName: String,
        showPosterPath: String?,
        episodes: [Episode]
    ) {
        self.id = id
        self.showId = showId
        self.showName = showName
        self.showPosterPath = showPosterPath
        self.createdAt = Date()
        self.lastModified = Date()
        self.initialSeeding = episodes.shuffled()
        self.comparisonResults = []
        self.currentComparisonIndex = 0
        self.isComplete = false
        self.winnerEpisode = nil
    }
}
