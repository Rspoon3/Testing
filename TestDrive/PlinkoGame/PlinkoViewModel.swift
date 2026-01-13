//
//  PlinkoViewModel.swift
//  TestDrive
//
//  Created by Claude on 2026.
//

import Foundation

/// View model that manages the game state for the Plinko game.
@Observable
final class PlinkoViewModel {

    /// The player's current score.
    private(set) var score: Int = 0

    /// The number of balls remaining.
    private(set) var ballsRemaining: Int = 10

    /// Whether the game is currently active.
    var isGameActive: Bool {
        ballsRemaining > 0
    }

    /// The high score for the current session.
    private(set) var highScore: Int = 0

    // MARK: - Public Helpers

    /// Adds points to the current score.
    /// - Parameter points: The points to add.
    func addScore(_ points: Int) {
        score += points
        if score > highScore {
            highScore = score
        }
    }

    /// Consumes a ball from the player's inventory.
    func consumeBall() {
        if ballsRemaining > 0 {
            ballsRemaining -= 1
        }
    }

    /// Resets the game to its initial state.
    func resetGame() {
        score = 0
        ballsRemaining = 10
    }
}
