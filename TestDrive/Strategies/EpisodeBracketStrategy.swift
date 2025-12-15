//
//  EpisodeBracketStrategy.swift
//  TestDrive
//

import Foundation

/// Single-elimination tournament bracket strategy for episodes.
///
/// Uses single-elimination rounds where episodes face off head-to-head.
/// Fastest method for finding the single best episode.
@MainActor
final class EpisodeBracketStrategy: EpisodeRankingStrategy {
    private var allEpisodes: [Episode]
    private var allComparisons: [(Episode, Episode)] = []
    private(set) var currentComparisonIndex = 0
    private(set) var comparisonResults: [Bool] = []

    /// Original shuffled order for deterministic replay.
    private(set) var initialSeeding: [Episode] = []

    /// Current round number (0-indexed).
    private var currentRound: Int = 0

    /// Episodes remaining in the current round.
    private var currentRoundBracket: [Episode] = []

    /// Tracks where each round starts in allComparisons.
    private var roundStartIndices: [Int] = []

    var totalComparisons: Int {
        allComparisons.count
    }

    var completedComparisons: Int {
        comparisonResults.count
    }

    var progress: Double {
        // For a single-elimination bracket, total comparisons = n - 1
        let expectedTotal = max(initialSeeding.count - 1, 1)
        return Double(completedComparisons) / Double(expectedTotal)
    }

    var canUndo: Bool {
        currentComparisonIndex > 0
    }

    var isComplete: Bool {
        // Complete when we have n-1 comparisons for n episodes
        guard !initialSeeding.isEmpty else { return false }
        return comparisonResults.count >= initialSeeding.count - 1
    }

    var currentComparison: (left: Episode, right: Episode)? {
        guard currentComparisonIndex < allComparisons.count else {
            return nil
        }
        let comparison = allComparisons[currentComparisonIndex]
        return (comparison.0, comparison.1)
    }

    // MARK: - Initializer

    init(episodes: [Episode]) {
        self.allEpisodes = episodes
    }

    // MARK: - Public Helpers

    func startRanking() {
        guard allEpisodes.count > 1 else {
            currentComparisonIndex = 0
            return
        }

        currentComparisonIndex = 0
        comparisonResults = []
        allComparisons = []
        currentRound = 0
        roundStartIndices = []

        // Seed episodes randomly once at the start
        initialSeeding = allEpisodes.shuffled()
        currentRoundBracket = initialSeeding

        // Generate only the first round (lazy generation)
        generateBracketComparisons()
    }

    func selectEpisode(isLeft: Bool) {
        guard currentComparisonIndex < allComparisons.count else { return }

        // Store the result
        if currentComparisonIndex < comparisonResults.count {
            // Replacing an existing result (after undo)
            comparisonResults[currentComparisonIndex] = isLeft
            // Remove any results after this point
            comparisonResults = Array(comparisonResults.prefix(currentComparisonIndex + 1))
        } else {
            // Adding new result
            comparisonResults.append(isLeft)
        }

        currentComparisonIndex += 1

        // Check if current round is complete and generate next round
        if currentRound < roundStartIndices.count {
            let roundStart = roundStartIndices[currentRound]
            let comparisonsInRound = currentRoundBracket.count / 2

            // If we've completed all comparisons in this round, generate next round
            if currentComparisonIndex == roundStart + comparisonsInRound {
                generateNextRound()
            }
        }
    }

    func undo() {
        guard currentComparisonIndex > 0 else { return }
        currentComparisonIndex -= 1

        // Check if we've undone past a round boundary
        // If so, remove later rounds and reset to the appropriate round
        while currentRound > 0 && currentComparisonIndex < roundStartIndices[currentRound] {
            // Remove comparisons from the later round
            let roundStart = roundStartIndices[currentRound]
            allComparisons.removeSubrange(roundStart...)
            roundStartIndices.removeLast()
            currentRound -= 1

            // Recalculate current round bracket
            if currentRound == 0 {
                currentRoundBracket = initialSeeding
            } else {
                // Rebuild bracket for this round from results
                var winners: [Episode] = []
                let prevRoundStart = roundStartIndices[currentRound - 1]
                let prevRoundComparisons = roundStartIndices[currentRound] - prevRoundStart

                for i in 0..<prevRoundComparisons {
                    let compIndex = prevRoundStart + i
                    if compIndex < comparisonResults.count {
                        let comparison = allComparisons[compIndex]
                        let winner = comparisonResults[compIndex] ? comparison.0 : comparison.1
                        winners.append(winner)
                    }
                }
                currentRoundBracket = winners
            }
        }
    }

    func getWinner() -> Episode? {
        guard isComplete else { return nil }

        // Replay the bracket using stored comparison results deterministically
        var currentBracket = initialSeeding
        var comparisonIndex = 0

        while currentBracket.count > 1 && comparisonIndex < comparisonResults.count {
            var nextRound: [Episode] = []

            for i in stride(from: 0, to: currentBracket.count - 1, by: 2) {
                if comparisonIndex < comparisonResults.count {
                    let winner: Episode
                    if comparisonResults[comparisonIndex] {
                        winner = currentBracket[i]
                    } else {
                        winner = currentBracket[i + 1]
                    }
                    nextRound.append(winner)
                    comparisonIndex += 1
                }
            }

            // Handle bye (odd bracket size)
            if currentBracket.count % 2 == 1 {
                if let lastEpisode = currentBracket.last {
                    nextRound.append(lastEpisode)
                }
            }

            currentBracket = nextRound
        }

        return currentBracket.first
    }

    func reset() {
        currentComparisonIndex = 0
        comparisonResults = []
        currentRound = 0
        currentRoundBracket = []
        roundStartIndices = []
        allComparisons = []
        startRanking()
    }

    func restore(seeding: [Episode], results: [Bool], index: Int) {
        // Restore the initial seeding
        initialSeeding = seeding
        currentRoundBracket = seeding
        comparisonResults = []
        allComparisons = []
        currentRound = 0
        roundStartIndices = []
        currentComparisonIndex = 0

        // Generate first round
        generateBracketComparisons()

        // Replay all the results to rebuild state
        for result in results {
            guard currentComparisonIndex < allComparisons.count else { break }
            selectEpisode(isLeft: result)
        }

        // Set the current index (may be same as results.count or less if undone)
        currentComparisonIndex = min(index, comparisonResults.count)
    }

    // MARK: - Private Helpers

    private func generateBracketComparisons() {
        roundStartIndices.append(allComparisons.count)

        // Pair adjacent episodes in current round bracket
        for i in stride(from: 0, to: currentRoundBracket.count - 1, by: 2) {
            allComparisons.append((currentRoundBracket[i], currentRoundBracket[i + 1]))
        }
    }

    private func generateNextRound() {
        // Calculate winners from the current round based on actual results
        var winners: [Episode] = []

        guard currentRound < roundStartIndices.count else { return }
        let roundStart = roundStartIndices[currentRound]
        let comparisonsInRound = currentRoundBracket.count / 2

        // Extract winners from this round's comparisons
        for i in 0..<comparisonsInRound {
            let comparisonIndex = roundStart + i
            guard comparisonIndex < comparisonResults.count else { break }

            let comparison = allComparisons[comparisonIndex]
            let winner = comparisonResults[comparisonIndex] ? comparison.0 : comparison.1
            winners.append(winner)
        }

        // Handle bye (odd bracket size from current round)
        if currentRoundBracket.count % 2 == 1 {
            if let last = currentRoundBracket.last {
                winners.append(last)
            }
        }

        // If we have more than one winner, generate the next round
        guard winners.count > 1 else { return }

        currentRound += 1
        currentRoundBracket = winners
        roundStartIndices.append(allComparisons.count)

        // Generate pairings for next round
        for i in stride(from: 0, to: winners.count - 1, by: 2) {
            allComparisons.append((winners[i], winners[i + 1]))
        }
    }
}
