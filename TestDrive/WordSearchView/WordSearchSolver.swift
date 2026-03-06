import SwiftUI

/// A coordinate in the word search grid.
struct GridPosition: Hashable {
    let row: Int
    let col: Int
}

/// A found word with its location in the grid and a unique highlight color.
struct FoundWord: Identifiable {
    let id = UUID()
    let word: String
    let positions: [GridPosition]
    let color: Color = Color(
        hue: .random(in: 0...1),
        saturation: .random(in: 0.5...0.9),
        brightness: .random(in: 0.5...0.85)
    )
}

/// Solves a word search puzzle by searching all 8 directions in a 2D character grid.
struct WordSearchSolver {
    /// All 8 search directions: right, left, down, up, and 4 diagonals.
    private static let directions: [(dr: Int, dc: Int)] = [
        (0, 1),   // right
        (0, -1),  // left
        (1, 0),   // down
        (-1, 0),  // up
        (1, 1),   // down-right
        (1, -1),  // down-left
        (-1, 1),  // up-right
        (-1, -1)  // up-left
    ]

    /// Searches the grid for all provided words.
    /// - Parameters:
    ///   - grid: A 2D array of uppercase characters representing the puzzle.
    ///   - words: The list of words to find (case-insensitive).
    /// - Returns: An array of `FoundWord` for each word located in the grid.
    static func solve(grid: [[Character]], words: [String]) -> [FoundWord] {
        guard !grid.isEmpty, !words.isEmpty else { return [] }

        let rows = grid.count
        let cols = grid[0].count
        let uppercasedWords = words.map { $0.uppercased() }

        let minLength = uppercasedWords.map(\.count).min() ?? 0
        let maxLength = uppercasedWords.map(\.count).max() ?? 0

        let wordSet = Set(uppercasedWords)
        var results: [FoundWord] = []

        for row in 0..<rows {
            for col in 0..<cols {
                for direction in directions {
                    for length in minLength...maxLength {
                        let endRow = row + direction.dr * (length - 1)
                        let endCol = col + direction.dc * (length - 1)

                        guard endRow >= 0, endRow < rows,
                              endCol >= 0, endCol < cols else { continue }

                        var candidate = ""
                        var positions: [GridPosition] = []

                        for step in 0..<length {
                            let r = row + direction.dr * step
                            let c = col + direction.dc * step
                            candidate.append(grid[r][c])
                            positions.append(GridPosition(row: r, col: c))
                        }

                        if wordSet.contains(candidate) {
                            let alreadyFound = results.contains { $0.word == candidate }
                            if !alreadyFound {
                                results.append(FoundWord(word: candidate, positions: positions))
                            }
                        }
                    }
                }
            }
        }

        return results
    }
}
