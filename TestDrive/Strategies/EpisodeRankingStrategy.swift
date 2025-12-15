//
//  EpisodeRankingStrategy.swift
//  TestDrive
//

import Foundation

/// Protocol defining the interface for episode ranking algorithms.
///
/// Concrete implementations handle generating comparisons, tracking progress,
/// and determining the winner.
@MainActor
protocol EpisodeRankingStrategy {
    /// Total number of comparisons that will be performed.
    var totalComparisons: Int { get }

    /// Number of comparisons completed so far.
    var completedComparisons: Int { get }

    /// Progress as a value between 0.0 and 1.0.
    var progress: Double { get }

    /// Whether undo functionality is currently available.
    var canUndo: Bool { get }

    /// Whether the ranking process is complete.
    var isComplete: Bool { get }

    /// The current pair of episodes being compared, or `nil` if complete.
    var currentComparison: (left: Episode, right: Episode)? { get }

    /// The initial seeding order (for persistence).
    var initialSeeding: [Episode] { get }

    /// The comparison results in order (for persistence).
    var comparisonResults: [Bool] { get }

    /// The current comparison index (for persistence).
    var currentComparisonIndex: Int { get }

    /// Initializes and starts the ranking process.
    func startRanking()

    /// Processes a user's selection between two episodes.
    /// - Parameter isLeft: `true` if the left episode was selected, `false` for right.
    func selectEpisode(isLeft: Bool)

    /// Undoes the last comparison.
    func undo()

    /// Gets the winning episode after ranking completes.
    /// - Returns: The winning episode, or `nil` if not complete.
    func getWinner() -> Episode?

    /// Resets the strategy to its initial state.
    func reset()

    /// Restores state from a saved session.
    /// - Parameters:
    ///   - seeding: The original shuffled episode order.
    ///   - results: The comparison results to replay.
    ///   - index: The current comparison index.
    func restore(seeding: [Episode], results: [Bool], index: Int)
}
