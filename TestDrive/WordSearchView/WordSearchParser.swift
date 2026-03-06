import os
import Vision

private let logger = Logger(subsystem: "com.testdrive", category: "WordSearchParser")

/// Result of parsing a word search image via OCR.
struct WordSearchParseResult {
    let grid: [[Character]]
    let words: [String]
}

/// Extracts a word search grid and word list from an image using Vision OCR.
enum WordSearchParser {

    /// Performs OCR on the image and returns the parsed grid and word list.
    /// - Parameter image: The word search image to process.
    /// - Returns: A `WordSearchParseResult` with the grid and words.
    static func parse(image: CGImage) throws -> WordSearchParseResult {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return WordSearchParseResult(grid: [], words: [])
        }

        let lines = extractLines(from: observations)
        let (gridLines, wordLines) = separateLines(lines)
        let grid = buildGrid(from: gridLines)
        let words = buildWordList(from: wordLines)

        logResults(grid: grid, words: words)

        return WordSearchParseResult(grid: grid, words: words)
    }

    // MARK: - Private Helpers

    private struct TextLine {
        let text: String
        let y: CGFloat
        let x: CGFloat
    }

    /// Extracts and sorts text lines from OCR observations by vertical position.
    private static func extractLines(from observations: [VNRecognizedTextObservation]) -> [TextLine] {
        observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return TextLine(
                text: candidate.string,
                y: 1.0 - observation.boundingBox.midY,
                x: observation.boundingBox.midX
            )
        }
        .sorted { $0.y < $1.y }
    }

    /// Separates lines into grid rows (single-spaced letters) and word list entries.
    private static func separateLines(_ lines: [TextLine]) -> (grid: [TextLine], words: [TextLine]) {
        var gridLines: [TextLine] = []
        var wordLines: [TextLine] = []

        for line in lines {
            let trimmed = line.text.trimmingCharacters(in: .whitespaces)

            if isSkippableLine(trimmed) { continue }

            let components = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
            let isSingleCharLine = components.count >= 5 && components.allSatisfy { $0.count == 1 }

            if isSingleCharLine {
                gridLines.append(line)
            } else {
                wordLines.append(line)
            }
        }

        return (gridLines, wordLines)
    }

    /// Returns whether a line should be skipped (title, copyright, etc.).
    private static func isSkippableLine(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return lowered.contains("production") ||
               lowered.contains("puzzles") ||
               text.contains("©")
    }

    /// Builds a normalized 2D character grid from grid text lines.
    private static func buildGrid(from gridLines: [TextLine]) -> [[Character]] {
        var grid: [[Character]] = gridLines.compactMap { line in
            let chars = line.text
                .components(separatedBy: " ")
                .filter { !$0.isEmpty }
                .compactMap { $0.uppercased().first }
            return chars.isEmpty ? nil : chars
        }

        guard let maxCols = grid.map(\.count).max() else { return [] }

        grid = grid.map { row in
            if row.count < maxCols {
                return row + Array(repeating: Character(" "), count: maxCols - row.count)
            }
            return row
        }

        return grid
    }

    /// Extracts individual words from the word list text lines.
    private static func buildWordList(from wordLines: [TextLine]) -> [String] {
        wordLines.flatMap { line in
            line.text
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .map { $0.trimmingCharacters(in: .punctuationCharacters).uppercased() }
                .filter { $0.count >= 2 && $0.allSatisfy(\.isLetter) }
        }
    }

    /// Logs the parsed grid and word list for debugging.
    private static func logResults(grid: [[Character]], words: [String]) {
        logger.info("Parsed grid: \(grid.count) rows x \(grid.first?.count ?? 0) cols")
        for (index, row) in grid.enumerated() {
            logger.info("Row \(index): \(String(row))")
        }
        logger.info("Parsed \(words.count) words: \(words.joined(separator: ", "))")
    }
}
