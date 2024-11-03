//
//  GameViewModel.swift
//  Testing
//
//  Created by Ricky on 11/2/24.
//

import SwiftUI

@Observable
final class GameViewModel {
    let colors = FlashableColor.allCases
    var showBorders: [Bool] = Array(repeating: false, count: FlashableColor.allCases.count)
    private(set) var currentPlayer: Player = .computer
    private(set) var round: Int = 1
    private(set) var gameEnded = false
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    private let difficulty: Difficulty = .easy
    private let startRoundCount = 1
    private var sequence: [FlashableColor] = []
    private var userSequence: [FlashableColor] = []
    
    
    var canTap: Bool {
        currentPlayer == .user
    }
    
    // MARK: - Public
    
    func startGame() async {
        withAnimation {
            round = 1
            currentPlayer = .computer
        }
        
        sequence = []
        userSequence = []
        setSequence(count: startRoundCount)
        
        try? await Task.sleep(for: .seconds(1))

        await flashSequence()
        
        try? await Task.sleep(for: .milliseconds(500))
        currentPlayer = .user
    }
    
    func stopGame() {
        sequence = []
        userSequence = []
        round = 1
        gameEnded = true
    }
    
    private func flashAndHaptic(index: Int, isCorrect: Bool) async {
        showBorders[index] = true
        await feedbackGenerator.notificationOccurred(isCorrect ? .success : .error)
        try? await Task.sleep(for: .milliseconds(900))
        showBorders[index] = false
    }
    
    func handleUserTap(color: FlashableColor) async {
        guard let index = colors.firstIndex(of: color) else { return }
        
        let isCorrect = userSequence == Array(sequence.prefix(userSequence.count))

        print("appending \(color)")
        userSequence.append(color)

        Task {
            await flashAndHaptic(
                index: index,
                isCorrect: isCorrect
            )
        }
        
        if isCorrect {
            print(userSequence.count, sequence.count)
            // Check if the user has completed the sequence
            guard userSequence.count == sequence.count else {
                // Wait for next user tap
                print("Correct but need to finish sequence")
                return
            }
            
            print("next round!")
            try? await Task.sleep(for: .seconds(1))
            await setupNextRound(sequenceCount: startRoundCount + round)
        } else {
            print("Game over")
            // User got it wrong
            stopGame()
        }
    }
    
    private func setupNextRound(sequenceCount: Int) async {
        currentPlayer = .computer
        userSequence = []
                    
        round += 1
        setSequence(count: sequenceCount)
        try? await Task.sleep(for: .seconds(1))

        await flashSequence()
        
        try? await Task.sleep(for: .seconds(1))
        currentPlayer = .user
    }

    
    // MARK: - Private
    
    private func setSequence(count: Int) {
        switch difficulty {
        case .easy:
            sequence.removeAll()
            
            for _ in 0..<count {
                let randomColor = colors.filter { $0 != sequence.last }.randomElement()!
                sequence.append(randomColor)
            }
        case .medium, .hard:
            sequence = Array(0..<count).map { _ in
                colors.randomElement()!
            }
        }
    }
    
    private func flashSequence() async {
        for color in sequence {
            guard let index = colors.firstIndex(of: color) else { continue }
            showBorders[index] = true
            try? await Task.sleep(for: .milliseconds(900))
            showBorders[index] = false
            try? await Task.sleep(for: .milliseconds(900))
        }
    }
}
