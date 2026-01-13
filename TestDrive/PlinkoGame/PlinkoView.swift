//
//  PlinkoView.swift
//  TestDrive
//
//  Created by Claude on 2026.
//

import SwiftUI
import SpriteKit

/// A SwiftUI view that displays the Plinko game.
struct PlinkoView: View {
    @State private var viewModel = PlinkoViewModel()
    @State private var scene: PlinkoScene?

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.15, green: 0.1, blue: 0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView
                    gameArea(size: geometry.size)
                    footerView
                }
            }
        }
        .onAppear {
            setupScene()
        }
    }

    // MARK: - Private Views

    /// The header showing score and balls remaining.
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SCORE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.score)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .center, spacing: 4) {
                Text("HIGH SCORE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.highScore)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("BALLS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    ForEach(0..<viewModel.ballsRemaining, id: \.self) { _ in
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    /// The main game area with the SpriteKit scene.
    /// - Parameter size: The available size for the game.
    private func gameArea(size: CGSize) -> some View {
        Group {
            if let scene {
                SpriteView(scene: scene)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    /// The footer with game controls.
    private var footerView: some View {
        VStack(spacing: 12) {
            if !viewModel.isGameActive {
                Text("Game Over!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            Text(viewModel.isGameActive ? "Tap the top of the board to drop a ball" : "")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                resetGame()
            } label: {
                Text(viewModel.isGameActive ? "Reset Game" : "Play Again")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.isGameActive ? Color.gray : Color.green)
                    )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Private Helpers

    /// Creates and configures the SpriteKit scene.
    private func setupScene() {
        let newScene = PlinkoScene()
        newScene.size = CGSize(width: 400, height: 600)
        newScene.scaleMode = .aspectFit

        newScene.onScoreUpdate = { points in
            viewModel.addScore(points)
        }

        newScene.onBallConsumed = {
            viewModel.consumeBall()
        }

        scene = newScene
    }

    /// Resets the game state and scene.
    private func resetGame() {
        viewModel.resetGame()
        setupScene()
    }
}

#Preview {
    PlinkoView()
}
