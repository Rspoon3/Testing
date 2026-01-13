//
//  PrizeWheelViewModel.swift
//  TestDrive
//

import SwiftUI

/// Configuration for a spin animation.
struct SpinConfiguration {
    let targetPrizeIndex: Int
    let numberOfRotations: Int
    let duration: TimeInterval

    // MARK: - Initializer

    /// Creates a new SpinConfiguration.
    /// - Parameters:
    ///   - targetPrizeIndex: The index of the prize to land on (0 to numberOfPrizes-1).
    ///   - numberOfRotations: How many complete cycles through all prizes before stopping.
    ///   - duration: How long the animation should take in seconds.
    init(
        targetPrizeIndex: Int,
        numberOfRotations: Int = 3,
        duration: TimeInterval = 4.0
    ) {
        self.targetPrizeIndex = targetPrizeIndex
        self.numberOfRotations = numberOfRotations
        self.duration = duration
    }
}

/// Manages the state and animation logic for the prize wheel.
@Observable
final class PrizeWheelViewModel {
    /// All prizes in the wheel.
    private(set) var prizes: [Prize]

    /// The number of visible tiles at once.
    let visibleTileCount: Int = 7

    /// Current offset in terms of prize indices (fractional).
    private(set) var currentOffset: CGFloat = 0

    /// Whether the wheel is currently spinning.
    private(set) var isSpinning: Bool = false

    /// The index of the prize currently at the selection point.
    private(set) var selectedPrizeIndex: Int = 0

    /// The prize that was just crossed (for threshold detection).
    private(set) var lastCrossedPrize: Prize?

    /// The winning prize when spin completes (nil while spinning).
    private(set) var completedPrize: Prize?

    private var spinStartTime: Date?
    private var spinConfiguration: SpinConfiguration?
    private var startOffset: CGFloat = 0
    private var targetOffset: CGFloat = 0
    private var lastCrossedIndex: Int = -1

    // MARK: - Initializer

    /// Creates a new PrizeWheelViewModel.
    /// - Parameter prizes: The list of prizes to display in the wheel.
    init(prizes: [Prize]) {
        self.prizes = prizes
    }

    // MARK: - Public Helpers

    /// Starts spinning the wheel with the given configuration.
    /// - Parameter configuration: The spin configuration specifying target, duration, etc.
    func spin(with configuration: SpinConfiguration) {
        guard !isSpinning else { return }
        guard configuration.targetPrizeIndex >= 0,
              configuration.targetPrizeIndex < prizes.count else { return }

        isSpinning = true
        completedPrize = nil
        spinConfiguration = configuration
        spinStartTime = Date()
        startOffset = currentOffset
        lastCrossedIndex = -1

        // Calculate total distance to travel
        // We need to go through numberOfRotations full cycles plus reach the target
        let fullCycleDistance = CGFloat(prizes.count)
        let rotationsDistance = fullCycleDistance * CGFloat(configuration.numberOfRotations)

        // Calculate how far we need to go to land on the target
        // The selection point is at the center of visible tiles (index 3 of 7 visible)
        let currentPrizeAtCenter = normalizedIndex(for: Int(currentOffset) + visibleTileCount / 2)
        var distanceToTarget = CGFloat(configuration.targetPrizeIndex - currentPrizeAtCenter)

        // Ensure we're moving forward (positive direction)
        if distanceToTarget <= 0 {
            distanceToTarget += fullCycleDistance
        }

        targetOffset = startOffset + rotationsDistance + distanceToTarget
    }

    /// Updates the animation state based on the current time.
    /// - Parameter date: The current date from TimelineView.
    func update(at date: Date) {
        guard isSpinning,
              let startTime = spinStartTime,
              let config = spinConfiguration else { return }

        let elapsed = date.timeIntervalSince(startTime)
        let progress = min(elapsed / config.duration, 1.0)

        // Apply ease-out curve: 1 - (1 - t)^3
        let easedProgress = easeOut(progress)

        // Calculate current offset
        let totalDistance = targetOffset - startOffset
        currentOffset = startOffset + (totalDistance * easedProgress)

        // Check for threshold crossings
        checkThresholdCrossing()

        // Update selected prize index
        selectedPrizeIndex = prizeIndexAtSelectionPoint()

        // Check if animation is complete
        if progress >= 1.0 {
            isSpinning = false
            spinStartTime = nil
            currentOffset = targetOffset
            selectedPrizeIndex = prizeIndexAtSelectionPoint()
            completedPrize = prizes[selectedPrizeIndex]
            spinConfiguration = nil
        }
    }

    /// Returns the prize at a given visual position.
    /// - Parameter visualIndex: The visual position (0 = top visible, 6 = bottom visible).
    /// - Returns: The prize at that position.
    func prize(at visualIndex: Int) -> Prize {
        let prizeIndex = normalizedIndex(for: Int(currentOffset) + visualIndex)
        return prizes[prizeIndex]
    }

    /// Returns the Y offset for a tile at the given visual index.
    /// - Parameters:
    ///   - visualIndex: The visual position of the tile.
    ///   - tileHeight: The height of each tile.
    /// - Returns: The Y offset to apply for smooth scrolling.
    func yOffset(for visualIndex: Int, tileHeight: CGFloat) -> CGFloat {
        let fractionalOffset = currentOffset.truncatingRemainder(dividingBy: 1.0)
        return -fractionalOffset * tileHeight
    }

    /// Returns the prize index currently at the selection point (center).
    /// - Returns: The index of the selected prize.
    func prizeIndexAtSelectionPoint() -> Int {
        let centerVisualIndex = visibleTileCount / 2
        return normalizedIndex(for: Int(round(currentOffset)) + centerVisualIndex)
    }

    // MARK: - Private Helpers

    /// Normalizes an index to wrap around the prize array.
    private func normalizedIndex(for index: Int) -> Int {
        let count = prizes.count
        var normalized = index % count
        if normalized < 0 {
            normalized += count
        }
        return normalized
    }

    /// Ease-out cubic curve: 1 - (1 - t)^3
    private func easeOut(_ t: CGFloat) -> CGFloat {
        let inverse = 1.0 - t
        return 1.0 - (inverse * inverse * inverse)
    }

    /// Checks if a prize has crossed the selection threshold and updates state.
    private func checkThresholdCrossing() {
        let currentSelectedIndex = prizeIndexAtSelectionPoint()

        if currentSelectedIndex != lastCrossedIndex {
            lastCrossedIndex = currentSelectedIndex
            lastCrossedPrize = prizes[currentSelectedIndex]
        }
    }
}
