//
//  EpisodeComparisonViewModel.swift
//  TestDrive
//

import Foundation

/// View model for the episode comparison screen.
@Observable
@MainActor
final class EpisodeComparisonViewModel {
    private(set) var session: RankingSession
    private var strategy: EpisodeBracketStrategy
    private let persistenceService: SessionPersistenceService

    // Observable state - updated after each action
    private(set) var currentComparison: (left: Episode, right: Episode)?
    private(set) var progress: Double = 0
    private(set) var canUndo: Bool = false
    private(set) var isComplete: Bool = false
    private(set) var winner: Episode?

    // MARK: - Initializer

    init(
        session: RankingSession,
        persistenceService: SessionPersistenceService = SessionPersistenceService()
    ) {
        self.session = session
        self.persistenceService = persistenceService

        // Create strategy and restore state
        self.strategy = EpisodeBracketStrategy(episodes: session.initialSeeding)

        // Restore the session state
        strategy.restore(
            seeding: session.initialSeeding,
            results: session.comparisonResults,
            index: session.currentComparisonIndex
        )

        // Initialize observable state
        updateState()
    }

    // MARK: - Public Helpers

    /// Selects an episode and saves progress.
    /// - Parameter isLeft: True if the left episode was selected.
    func selectEpisode(isLeft: Bool) {
        strategy.selectEpisode(isLeft: isLeft)
        updateState()
        Task {
            await saveProgress()
        }
    }

    /// Undoes the last comparison.
    func undo() {
        strategy.undo()
        updateState()
        Task {
            await saveProgress()
        }
    }

    /// Completes the session and saves the winner.
    func completeSession() async {
        guard let winner = strategy.getWinner() else { return }

        session.isComplete = true
        session.winnerEpisode = winner
        session.comparisonResults = strategy.comparisonResults
        session.currentComparisonIndex = strategy.currentComparisonIndex

        do {
            try await persistenceService.update(session)
        } catch {
            print("Failed to save completed session: \(error)")
        }
    }

    // MARK: - Private Helpers

    private func updateState() {
        currentComparison = strategy.currentComparison
        progress = strategy.progress
        canUndo = strategy.canUndo
        isComplete = strategy.isComplete
        winner = strategy.getWinner()
    }

    private func saveProgress() async {
        session.comparisonResults = strategy.comparisonResults
        session.currentComparisonIndex = strategy.currentComparisonIndex

        do {
            try await persistenceService.update(session)
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
}
