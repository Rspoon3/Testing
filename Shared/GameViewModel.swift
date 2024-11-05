//
//  GameViewModel.swift
//  Testing
//
//  Created by Ricky on 11/2/24.
//

import SwiftUI

@MainActor
@Observable
final class GameViewModel {
    private let possibleValues = [0, 1, 2, 3]
    private(set) var selectedIndex: Int?
    private(set) var currentPlayer: Player = .computer
    private(set) var round: Int = 1
    private(set) var gameEnded = false
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    private let difficulty: Difficulty = .easy
    private let startRoundCount = 1
    private var sequence: [Int] = []
    private var userSequence: [Int] = []
    
    
    var canTap: Bool {
        currentPlayer == .user
    }
    
    // MARK: - Public
    
    func startGame() async {
        print("Start!")
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
        
        withAnimation {
            gameEnded = true
        }
    }
    
    private func flashAndHaptic(index: Int, isCorrect: Bool) async {
        feedbackGenerator.notificationOccurred(isCorrect ? .success : .error)

        if isCorrect {
            selectedIndex = index
        }
        
        try? await Task.sleep(for: .milliseconds(500))
        
        if index == selectedIndex {
            selectedIndex = nil
        }
    }
    
    func resetGame() async {
        withAnimation {
            gameEnded = false
        }
//        try? await Task.sleep(for: .milliseconds(500))
        await startGame()
    }
    
    func handleUserTap(index: Int) async {
        userSequence.append(index)
        
        let isCorrect = (userSequence == Array(sequence.prefix(userSequence.count)))

        print("appending \(index)", isCorrect)
        print("appending \(index)", isCorrect)
        
        Task {
            await flashAndHaptic(
                index: index,
                isCorrect: isCorrect
            )
        }
        print("appending \(index)", isCorrect)
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
        
        try? await Task.sleep(for: .milliseconds(500))
        currentPlayer = .user
    }

    
    // MARK: - Private
    
    private func setSequence(count: Int) {
        switch difficulty {
        case .easy:
            sequence.removeAll()
            
            for _ in 0..<count {
                let randomInt = possibleValues.filter { $0 != sequence.last }.randomElement()!
                sequence.append(randomInt)
            }
        case .medium, .hard:
            sequence = Array(0..<count).map { _ in
                possibleValues.randomElement()!
            }
        }
    }
    
    private func flashSequence() async {
        print("Flash! ", sequence)
        for value in sequence {
            print("Flashing value: \(value)")
            selectedIndex = value
            try? await Task.sleep(for: .milliseconds(500))
            
            if value == selectedIndex {
                selectedIndex = nil
            }
            try? await Task.sleep(for: .milliseconds(500))
        }
    }
}

import OSLog

/// Debug, Info, Notice, Error, Fault
///
/// Debug is not persisted, info is persisted only during "log collect", and notice, error, and fault
/// are persisted up to a storage limit.
public extension Logger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.rspoon3.ShotbotFrames"
    
    init(category: String) {
        self.init(
            subsystem: Logger.subsystem,
            category: category
        )
    }
    
    init<T>(category type: T.Type) {
        self.init(
            subsystem: Logger.subsystem,
            category: String(describing: type)
        )
    }
}

extension Logger: @unchecked Sendable {}


/// An object that is responsible for prompting the user for a review if the acceptance criteria
/// is met.
@MainActor
public struct ReviewManager {
    private let logger = Logger(category: ReviewManager.self)
    
    // MARK: - Initializer

    // MARK: - Public
    
    /// Asks the user for a review if the acceptance criteria is met.
    public func askForAReview() {
        let numberOfActivations = persistenceManager.numberOfActivations
        
        guard deviceFrameCreations > 3 && numberOfActivations > 3 else {
            logger.debug("Review prompt criteria not met. DeviceFrameCreations: \(deviceFrameCreations, privacy: .public), numberOfActivations: \(numberOfActivations, privacy: .public).")
            return
        }
        
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            logger.fault("Could not find UIWindowScene to ask for review")
            return
        }
        
        if let date = persistenceManager.lastReviewPromptDate {
            guard date >= Date.now.adding(3, .day) else {
                logger.debug("Last review prompt date to recent: \(date, privacy: .public).")
                return
            }
        }
        
        skStoreReviewController.requestReview(in: scene)
        persistenceManager.setLastReviewPromptDateToNow()
        logger.log("Prompting the user for a review")
    }
}
