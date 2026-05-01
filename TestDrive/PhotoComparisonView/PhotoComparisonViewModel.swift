//
//  PhotoComparisonViewModel.swift
//  TestDrive
//

import SwiftUI

@MainActor
class PhotoComparisonViewModel: ObservableObject {
    @Published var currentComparison: (left: PhotoItem, right: PhotoItem)?
    @Published var totalComparisons = 0
    @Published var completedComparisons = 0
    @Published var canUndo = false
    @Published var rankingComplete = false
    @Published var rankedPhotos: [PhotoItem] = []

    private var allPhotos: [PhotoItem] = []
    private var allComparisons: [(PhotoItem, PhotoItem)] = []
    private var currentComparisonIndex = 0
    private var comparisonResults: [Bool] = []

    var progress: Double {
        Double(completedComparisons) / Double(max(totalComparisons, 1))
    }

    // MARK: - Initializer

    init(photos: [PhotoItem]) {
        self.allPhotos = photos
        startRanking()
    }

    // MARK: - Public Helpers

    func selectPhoto(isLeft: Bool) {
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

        completedComparisons = comparisonResults.count
        currentComparisonIndex += 1

        showNextComparison()
    }

    func undoLastComparison() {
        guard currentComparisonIndex > 0 else { return }

        currentComparisonIndex -= 1
        completedComparisons = max(0, completedComparisons - 1)

        showNextComparison()
    }

    // MARK: - Private Helpers

    private func startRanking() {
        guard allPhotos.count > 1 else {
            calculateFinalRanking()
            return
        }

        completedComparisons = 0
        currentComparisonIndex = 0
        comparisonResults = []
        canUndo = false

        // Generate all comparison pairs needed for ranking
        generateAllComparisons()

        // Estimate total comparisons
        totalComparisons = allComparisons.count

        // Start with first comparison
        showNextComparison()
    }

    private func generateAllComparisons() {
        allComparisons = []

        // Generate all pairs for bubble sort style comparisons
        for i in 0..<allPhotos.count {
            for j in (i + 1)..<allPhotos.count {
                allComparisons.append((allPhotos[i], allPhotos[j]))
            }
        }
    }

    private func showNextComparison() {
        if currentComparisonIndex < allComparisons.count {
            let comparison = allComparisons[currentComparisonIndex]
            currentComparison = (comparison.0, comparison.1)
            canUndo = currentComparisonIndex > 0
        } else {
            // All comparisons done, calculate final ranking
            calculateFinalRanking()
        }
    }

    private func calculateFinalRanking() {
        // Calculate win counts for each photo
        var winCounts: [PhotoItem: Int] = [:]

        for photo in allPhotos {
            winCounts[photo] = 0
        }

        // Count wins based on comparison results
        for (index, comparison) in allComparisons.enumerated() {
            guard index < comparisonResults.count else { break }

            let winner = comparisonResults[index] ? comparison.0 : comparison.1
            winCounts[winner, default: 0] += 1
        }

        // Sort photos by win count (descending)
        var sortedPhotos = allPhotos.sorted { photo1, photo2 in
            winCounts[photo1, default: 0] > winCounts[photo2, default: 0]
        }

        // Assign ranks
        for index in 0..<sortedPhotos.count {
            sortedPhotos[index].rank = index + 1
        }

        rankedPhotos = sortedPhotos
        currentComparison = nil
        rankingComplete = true
    }
}
