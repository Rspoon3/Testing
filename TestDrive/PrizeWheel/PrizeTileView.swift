//
//  PrizeTileView.swift
//  TestDrive
//

import SwiftUI

/// Displays a single prize tile in the wheel.
struct PrizeTileView: View {
    private let prize: Prize
    private let height: CGFloat

    // MARK: - Initializer

    /// Creates a new PrizeTileView.
    /// - Parameters:
    ///   - prize: The prize to display.
    ///   - height: The height of the tile.
    init(prize: Prize, height: CGFloat) {
        self.prize = prize
        self.height = height
    }

    // MARK: - Body

    var body: some View {
        Text(prize.title)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: height)
            .background(prize.color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    PrizeTileView(
        prize: Prize(title: "🎁 Grand Prize", color: .blue, index: 0),
        height: 60
    )
    .padding()
}
