import CoreImage
import CoreImage.CIFilterBuiltins
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
        let processedImage = preprocessImage(image) ?? image

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.01

        let handler = VNImageRequestHandler(cgImage: processedImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return WordSearchParseResult(grid: [], words: [])
        }

        let lines = extractLines(from: observations)

        for line in lines {
            logger.debug("OCR line (y=\(String(format: "%.3f", line.y))): '\(line.text)'")
        }

        let (gridLines, wordLines) = separateLines(lines)
        let grid = buildGrid(from: gridLines)
        let words = buildWordList(from: wordLines)

        logResults(grid: grid, words: words)

        return WordSearchParseResult(grid: grid, words: words)
    }

    // MARK: - Private Helpers

    /// Converts the image to high-contrast grayscale to improve OCR accuracy on grid characters.
    private static func preprocessImage(_ image: CGImage) -> CGImage? {
        let ciImage = CIImage(cgImage: image)
        let context = CIContext()

        // Convert to grayscale and boost contrast
        let grayscale = ciImage.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.0,
            kCIInputContrastKey: 2.0,
            kCIInputBrightnessKey: 0.1
        ])

        // Sharpen to make character edges crisper
        let sharpened = grayscale.applyingFilter("CISharpenLuminance", parameters: [
            kCIInputSharpnessKey: 1.5
        ])

        return context.createCGImage(sharpened, from: sharpened.extent)
    }

    private struct TextLine {
        let text: String
        let y: CGFloat
        let x: CGFloat
    }

    /// Extracts text observations, merges fragments on the same Y-line, and sorts by vertical position.
    private static func extractLines(from observations: [VNRecognizedTextObservation]) -> [TextLine] {
        // Extract raw fragments
        let fragments: [TextLine] = observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return TextLine(
                text: candidate.string,
                y: 1.0 - observation.boundingBox.midY,
                x: observation.boundingBox.midX
            )
        }

        // Group fragments that share the same Y position (within a tolerance)
        // Vision may split a single grid row into multiple observations
        let yTolerance: CGFloat = 0.008
        var rows: [[TextLine]] = []

        for fragment in fragments.sorted(by: { $0.y < $1.y }) {
            if let lastIndex = rows.lastIndex(where: { row in
                abs(row[0].y - fragment.y) < yTolerance
            }) {
                rows[lastIndex].append(fragment)
            } else {
                rows.append([fragment])
            }
        }

        // Merge each group into a single line, ordering fragments left-to-right
        return rows.map { group in
            let sorted = group.sorted { $0.x < $1.x }
            let mergedText = sorted.map(\.text).joined(separator: " ")
            let avgY = sorted.map(\.y).reduce(0, +) / CGFloat(sorted.count)
            let minX = sorted.map(\.x).min() ?? 0
            return TextLine(text: mergedText, y: avgY, x: minX)
        }
        .sorted { $0.y < $1.y }
    }

    /// Separates lines into grid rows and word list entries by finding the largest
    /// vertical gap between consecutive lines. Everything above the gap (excluding the
    /// title) is the grid; everything below is the word list.
    private static func separateLines(_ lines: [TextLine]) -> (grid: [TextLine], words: [TextLine]) {
        let candidates = lines.filter { !isSkippableLine($0.text) }

        guard candidates.count >= 2 else {
            return ([], candidates)
        }

        // Find the largest vertical gap between consecutive lines
        var largestGap: CGFloat = 0
        var splitIndex = 0

        for i in 1..<candidates.count {
            let gap = candidates[i].y - candidates[i - 1].y
            if gap > largestGap {
                largestGap = gap
                splitIndex = i
            }
        }

        let gridLines = Array(candidates[0..<splitIndex])
        let wordLines = Array(candidates[splitIndex...])

        logger.debug("Split at index \(splitIndex) with gap \(String(format: "%.4f", largestGap)) — \(gridLines.count) grid lines, \(wordLines.count) word lines")

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
    /// Handles both space-separated characters ("L S H O O") and continuous strings ("LSHOO").
    private static func buildGrid(from gridLines: [TextLine]) -> [[Character]] {
        var grid: [[Character]] = gridLines.compactMap { line in
            let components = line.text
                .components(separatedBy: " ")
                .filter { !$0.isEmpty }
            let isSpaceSeparated = components.count >= 5 && components.allSatisfy { $0.count == 1 }

            let chars: [Character]
            if isSpaceSeparated {
                chars = components.compactMap { $0.uppercased().first }
            } else {
                // Continuous string — split into individual characters
                chars = Array(line.text.replacingOccurrences(of: " ", with: "").uppercased())
                    .filter(\.isLetter)
            }

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
