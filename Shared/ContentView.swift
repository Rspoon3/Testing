//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    let columns: Int = 17  // 15 + 2 for labels
    let rows: Int = 32     // 30 + 2 for labels
    let letters = Array("ABCDEFGHIJKLMNO") // Replaces UnicodeScalar

    var items: [Item] {
        var items: [Item] = []
        
        for row in 0..<rows {
            for col in 0..<columns {
                let id = "\(row)-\(col)"
                
                // Corners should be blank
                if (row == 0 || row == rows - 1) && (col == 0 || col == columns - 1) {
                    items.append(Item(id: id, kind: .blank))
                }
                // Top & Bottom Rows (Letters A-O)
                else if row == 0 {
                    items.append(Item(id: id, kind: .label(String(letters[col - 1])))) // Top Labels (A-O)
                } else if row == rows - 1 {
                    items.append(Item(id: id, kind: .label(String(letters[col - 1])))) // Bottom Labels (A-O)
                }
                // Left & Right Columns (Numbers 1-30)
                else if col == 0 {
                    items.append(Item(id: id, kind: .label("\(row)"))) // Left Labels (1-30)
                } else if col == columns - 1 {
                    items.append(Item(id: id, kind: .label("\(row)"))) // Right Labels (1-30)
                }
                // Interior (Color Blending)
                else {
                    let adjustedCol = col - 1 // Shift to align with the correct range
                    let adjustedRow = row - 1 // Shift to align with the correct range
                    
                    let startHue = Double(adjustedCol) / Double(columns - 2)
                    let nextHue = Double(adjustedCol + 1) / Double(columns - 2)
                    let blendFactor = Double(adjustedRow) / Double(rows - 2)
                    
                    let blendedHue = (startHue * (1 - blendFactor)) + (nextHue * blendFactor)
                    let saturation = 0.9
                    let brightness = 1.0 - (blendFactor * 0.2)
                    
                    let uiColor = UIColor(
                        hue: CGFloat(blendedHue),
                        saturation: CGFloat(saturation),
                        brightness: CGFloat(brightness),
                        alpha: 1.0
                    )
                    let hexString = uiColor.toHex() ?? "#FFFFFF"
                    
                    // Generate grid identifier (e.g., "A5", "J13")
                    let gridLetter = letters[adjustedCol] // Safer than UnicodeScalar
                    let gridIdentifier = "\(gridLetter)\(adjustedRow + 1)"
                    
                    let colorItem = ColorItem(hex: hexString, id: gridIdentifier, row: adjustedRow, col: adjustedCol)
                    items.append(Item(id: id, kind: .color(colorItem)))
                }
            }
        }
        return items
    }
    
    private let playerCount = 4
    let possibleGuessesColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 1), count: 2)
    let gridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 1), count: 17)
    @State private var selectedColorItem: ColorItem?
    @State private var possibleGuesses: [ColorItem] = []
    
    var body: some View {
        ScrollView {
            guessCard
            gameBoard
        }
    }
    
    // MARK: - Private Views
    private var gameBoard: some View {
        LazyVGrid(columns: gridColumns, spacing: 1) {
            ForEach(items) { item in

                switch item.kind {
                case .color(let colorItem):
                    let distance = getDistance(to: colorItem)

                    (Color(hex: colorItem.hex) ?? .black)
                        .frame(height: 20)
                        .overlay { Text(colorItem.id) }
                        .border(Color.black, width: selectedColorItem == colorItem ? 2 : 0)
                        .accessibilityAddTraits(.isButton)
                        .opacity(distance == 1 ? 0.5 : distance == 2 ? 0.25 : 1.0) // Opacity logic
                        .onTapGesture {
                            withAnimation {
                                if selectedColorItem == colorItem {
                                    selectedColorItem = nil
                                } else {
                                    selectedColorItem = colorItem
                                }
                            }
                        }
                case .label(let text):
                    Text(text)
                        .font(.caption)
                        .frame(height: 20)
                case .blank:
                    Text("")
                        .frame(height: 20)
                }
            }
        }
        .padding(5)
        .onAppear {
            while possibleGuesses.count != 4 {
                let random = getRandomColorItem()
                if !possibleGuesses.contains(random) {
                    possibleGuesses.append(random)
                }
            }
        }
    }
    
    @ViewBuilder
    private var guessCard: some View {
        if !possibleGuesses.isEmpty {
            Grid(alignment: .center, horizontalSpacing: 5, verticalSpacing: 5) {
                GridRow {
                    ForEach(possibleGuesses.prefix(2)) { guess in
                        VStack(spacing: 2) {
                            Color(hex: guess.hex)!
                                .frame(width: 30, height: 30)
                            Text(guess.id)
                                .font(.caption)
                        }
                        .onTapGesture {
                            withAnimation {
                                if selectedColorItem == guess {
                                    selectedColorItem = nil
                                } else {
                                    selectedColorItem = guess
                                }
                            }
                        }
                    }
                }
                GridRow {
                    ForEach(possibleGuesses.dropFirst(2).prefix(2)) { guess in
                        VStack(spacing: 2) {
                            Color(hex: guess.hex)!
                                .frame(width: 30, height: 30)
                            Text(guess.id)
                                .font(.caption)
                        }
                        .onTapGesture {
                            withAnimation {
                                if selectedColorItem == guess {
                                    selectedColorItem = nil
                                } else {
                                    selectedColorItem = guess
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func getRandomColorItem() -> ColorItem {
        let colorItems = items.compactMap { item -> ColorItem? in
            guard case let .color(colorItem) = item.kind else { return nil }
            return colorItem
        }
        return colorItems.randomElement()!
    }
    
    private func getDistance(to colorItem: ColorItem) -> Int {
        guard let selected = selectedColorItem else { return 0 }
        
        let rowDiff = abs(selected.row - colorItem.row)
        let colDiff = abs(selected.col - colorItem.col)
        
        let maxDiff = max(rowDiff, colDiff) // Use max to measure the furthest step
        
        return maxDiff // Returns 1 for adjacent, 2 for one step further, etc.
    }
}

#Preview {
    ContentView()
}

struct Player: Hashable, Equatable, Identifiable, Sendable {
    let id: Int
}

enum GameState {
    case idle
    case colorPicker(player: Player)
    case guesserTurn(player: Player)
    case gameOver(ranks: [Player])
}

final class GameViewModel {
    var state = GameState.idle
    var hint: String?
    var selectedColorItemHex: String?
    var colorGuesses: [Player: [ColorItem]] = [:]
    var scores: [Player: Int] = [:]
    private let players = [Player(id: 1), Player(id: 2), Player(id: 3), Player(id: 4)]
    
    func startGame() {
        state = .colorPicker(player: players[0])
        selectedColorItemHex = "3ef345"
        hint = "bannana"
    }
    
    func userDidPick(colorItem: ColorItem) {
        guard let selectedColorItemHex, let hint else { return }
        colorGuesses[players[0]]
        state = .colorPicker(
            player: players[0],
            state: .picked(
                hint: hint,
                colorHex: selectedColorItemHex
            )
        )
    }
}

/*
 On Appear
 
 Player 1 becomes the colorPicker
 Player 1 picks a color
 Player 1 gives a one word hint
 
 Player 2 picks a color
 Player 3 picks a color
 Player 4 picks a color
 
 Player 1 gives a two word hint

 Player 2 picks another color
 Player 3 picks another color
 Player 4 picks another color
 
 Scores are calculated
 
 --------
 
 Player 2 becomes the colorPicker
 
 Player 2 picks a color
 Player 2 gives a one word hint
 
 Player 1 picks a color
 Player 3 picks a color
 Player 4 picks a color
 
 Player 2 gives a two word hint

 Player 1 picks another color
 Player 3 picks another color
 Player 4 picks another color
 
 Scores are calculated
 
 --------
 
 Player 3 becomes the colorPicker
 
 Player 3 picks a color
 Player 3 gives a one word hint
 
 Player 1 picks a color
 Player 2 picks a color
 Player 4 picks a color
 
 Player 3 gives a two word hint

 Player 1 picks another color
 Player 2 picks another color
 Player 4 picks another color
 
 Scores are calculated
 
 --------
 
 Player 4 becomes the colorPicker
 
 Player 4 picks a color
 Player 4 gives a one word hint
 
 Player 1 picks a color
 Player 2 picks a color
 Player 3 picks a color
 
 Player 4 gives a two word hint

 Player 1 picks another color
 Player 2 picks another color
 Player 3 picks another color
 
 Scores are calculated

 --------

 Game over.
 Rank players
 */
