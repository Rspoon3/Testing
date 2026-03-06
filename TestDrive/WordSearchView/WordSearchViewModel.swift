import os
import SwiftUI
import PhotosUI

private let logger = Logger(subsystem: "com.testdrive", category: "WordSearchViewModel")

/// View model that handles image selection, OCR text recognition, and word search solving.
@Observable
final class WordSearchViewModel {
    var selectedItem: PhotosPickerItem?
    var selectedImage: UIImage?
    var grid: [[Character]] = []
    var words: [String] = []
    var foundWords: [FoundWord] = []
    var isProcessing = false
    var errorMessage: String?

    /// The set of found word strings for highlighting in the word list.
    var foundWordStrings: Set<String> {
        Set(foundWords.map(\.word))
    }

    // MARK: - Public Helpers

    /// Loads the image from the selected `PhotosPickerItem` and begins processing.
    func loadImage() async {
        guard let selectedItem else { return }

        isProcessing = true
        errorMessage = nil
        grid = []
        words = []
        foundWords = []

        do {
            guard let data = try await selectedItem.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                errorMessage = "Failed to load image."
                isProcessing = false
                return
            }

            selectedImage = uiImage
            try processImage(uiImage)
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    /// Returns the color for a found word, or gray if not found.
    func color(for word: String) -> Color {
        foundWords.first { $0.word == word.uppercased() }?.color ?? .gray
    }

    /// Returns the color for a specific grid position, or nil if not highlighted.
    func color(for position: GridPosition) -> Color? {
        foundWords.first { $0.positions.contains(position) }?.color
    }

    // MARK: - Private Helpers

    /// Runs OCR parsing and the word search solver on the image.
    private func processImage(_ image: UIImage) throws {
        guard let cgImage = image.cgImage else {
            errorMessage = "Failed to process image."
            return
        }

        let result = try WordSearchParser.parse(image: cgImage)
        grid = result.grid
        words = result.words

        guard !grid.isEmpty, !words.isEmpty else { return }

        foundWords = WordSearchSolver.solve(grid: grid, words: words)
        logSolverResults()
    }

    /// Logs solver results for debugging.
    private func logSolverResults() {
        logger.info("Found \(self.foundWords.count)/\(self.words.count) words")
        for found in foundWords {
            let start = found.positions.first.map { "(\($0.row),\($0.col))" } ?? "?"
            let end = found.positions.last.map { "(\($0.row),\($0.col))" } ?? "?"
            logger.info("  \(found.word): \(start) -> \(end)")
        }

        let missing = words.filter { word in !foundWordStrings.contains(word) }
        if !missing.isEmpty {
            logger.warning("Missing words: \(missing.joined(separator: ", "))")
        }
    }
}
