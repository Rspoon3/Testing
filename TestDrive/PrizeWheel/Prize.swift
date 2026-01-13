//
//  Prize.swift
//  TestDrive
//

import SwiftUI

/// Represents a single prize in the wheel.
struct Prize: Identifiable, Equatable {
    let id: UUID
    let title: String
    let color: Color
    let index: Int

    // MARK: - Initializer

    /// Creates a new Prize.
    /// - Parameters:
    ///   - id: Unique identifier for the prize.
    ///   - title: Display title for the prize.
    ///   - color: Background color for the prize tile.
    ///   - index: The index position in the prize list.
    init(id: UUID = UUID(), title: String, color: Color, index: Int) {
        self.id = id
        self.title = title
        self.color = color
        self.index = index
    }
}
