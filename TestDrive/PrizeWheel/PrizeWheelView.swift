//
//  PrizeWheelView.swift
//  TestDrive
//

import SwiftUI

/// A vertical slot machine-style prize wheel using TimelineView.
struct PrizeWheelView: View {
    @State private var viewModel: PrizeWheelViewModel
    private let tileHeight: CGFloat
    private let tileSpacing: CGFloat
    private let onPrizeCrossedThreshold: ((Prize) -> Void)?

    // MARK: - Initializer

    /// Creates a new PrizeWheelView.
    /// - Parameters:
    ///   - prizes: The list of prizes to display.
    ///   - tileHeight: The height of each prize tile.
    ///   - tileSpacing: The spacing between tiles.
    ///   - onPrizeCrossedThreshold: Called when a prize crosses the selection point during spin.
    init(
        prizes: [Prize],
        tileHeight: CGFloat = 60,
        tileSpacing: CGFloat = 4,
        onPrizeCrossedThreshold: ((Prize) -> Void)? = nil
    ) {
        self._viewModel = State(initialValue: PrizeWheelViewModel(prizes: prizes))
        self.tileHeight = tileHeight
        self.tileSpacing = tileSpacing
        self.onPrizeCrossedThreshold = onPrizeCrossedThreshold
    }

    // MARK: - Body

    var body: some View {
        TimelineView(.animation(paused: !viewModel.isSpinning)) { timeline in
            wheelContent(at: timeline.date)
        }
        .onChange(of: viewModel.lastCrossedPrize) { _, newPrize in
            if let prize = newPrize {
                onPrizeCrossedThreshold?(prize)
            }
        }
    }

    // MARK: - Private Views

    private func wheelContent(at date: Date) -> some View {
        let _ = viewModel.update(at: date)

        return GeometryReader { geometry in
            let totalTileHeight = tileHeight + tileSpacing
            let visibleHeight = totalTileHeight * CGFloat(viewModel.visibleTileCount)
            let renderCount = viewModel.visibleTileCount + 2
            let scrollOffset = viewModel.yOffset(for: 0, tileHeight: totalTileHeight)

            ZStack(alignment: .top) {
                VStack(spacing: tileSpacing) {
                    ForEach(0..<renderCount, id: \.self) { index in
                        let visualIndex = index - 1
                        let prize = viewModel.prize(at: visualIndex)
                        PrizeTileView(prize: prize, height: tileHeight)
                    }
                }
                .offset(y: -totalTileHeight + scrollOffset)

                selectionIndicator(height: tileHeight, totalHeight: visibleHeight)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(width: geometry.size.width, height: visibleHeight, alignment: .top)
            .clipped()
        }
        .frame(height: (tileHeight + tileSpacing) * CGFloat(viewModel.visibleTileCount))
    }

    private func selectionIndicator(height: CGFloat, totalHeight: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.yellow, lineWidth: 3)
            .frame(height: height + 4)
            .shadow(color: .yellow.opacity(0.5), radius: 4)
    }

    // MARK: - Public Helpers

    /// Starts the wheel spinning to land on the specified prize.
    /// - Parameters:
    ///   - targetPrizeIndex: The index of the prize to land on.
    ///   - numberOfRotations: How many full cycles before stopping.
    ///   - duration: The total animation duration.
    ///   - completion: Called when the spin completes.
    func spin(
        to targetPrizeIndex: Int,
        numberOfRotations: Int = 3,
        duration: TimeInterval = 4.0,
        completion: (() -> Void)? = nil
    ) {
        let config = SpinConfiguration(
            targetPrizeIndex: targetPrizeIndex,
            numberOfRotations: numberOfRotations,
            duration: duration,
            completion: completion
        )
        viewModel.spin(with: config)
    }
}

/// A self-contained prize wheel with integrated spin button.
struct PrizeWheelContainer: View {
    private let prizes: [Prize]
    private let tileHeight: CGFloat
    private let tileSpacing: CGFloat
    private let onPrizeCrossedThreshold: ((Prize) -> Void)?
    private let onSpinComplete: ((Prize) -> Void)?
    @State private var viewModel: PrizeWheelViewModel

    // MARK: - Initializer

    /// Creates a new PrizeWheelContainer.
    /// - Parameters:
    ///   - prizes: The list of prizes to display.
    ///   - tileHeight: The height of each prize tile.
    ///   - tileSpacing: The spacing between tiles.
    ///   - onPrizeCrossedThreshold: Called when a prize crosses the selection point.
    ///   - onSpinComplete: Called when the spin animation completes with the winning prize.
    init(
        prizes: [Prize],
        tileHeight: CGFloat = 60,
        tileSpacing: CGFloat = 4,
        onPrizeCrossedThreshold: ((Prize) -> Void)? = nil,
        onSpinComplete: ((Prize) -> Void)? = nil
    ) {
        self.prizes = prizes
        self.tileHeight = tileHeight
        self.tileSpacing = tileSpacing
        self._viewModel = State(initialValue: PrizeWheelViewModel(prizes: prizes))
        self.onPrizeCrossedThreshold = onPrizeCrossedThreshold
        self.onSpinComplete = onSpinComplete
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            TimelineView(.animation(paused: !viewModel.isSpinning)) { timeline in
                wheelContent(at: timeline.date)
            }

            spinButton
        }
        .onChange(of: viewModel.lastCrossedPrize) { _, newPrize in
            if let prize = newPrize {
                onPrizeCrossedThreshold?(prize)
            }
        }
        .onChange(of: viewModel.completedPrize) { _, newPrize in
            if let prize = newPrize {
                onSpinComplete?(prize)
            }
        }
    }

    // MARK: - Private Views

    private func wheelContent(at date: Date) -> some View {
        let _ = viewModel.update(at: date)
        let totalTileHeight = tileHeight + tileSpacing
        let visibleHeight = totalTileHeight * CGFloat(viewModel.visibleTileCount)
        // Render extra tiles above and below for smooth scrolling
        let renderCount = viewModel.visibleTileCount + 2
        // Calculate scroll offset (moves tiles upward as offset increases)
        let scrollOffset = viewModel.yOffset(for: 0, tileHeight: totalTileHeight)

        return ZStack(alignment: .top) {
            VStack(spacing: tileSpacing) {
                ForEach(0..<renderCount, id: \.self) { index in
                    // Start one tile above visible area
                    let visualIndex = index - 1
                    let prize = viewModel.prize(at: visualIndex)
                    PrizeTileView(prize: prize, height: tileHeight)
                }
            }
            // Position: start with extra tile hidden above (-totalTileHeight), then apply scroll
            .offset(y: -totalTileHeight + scrollOffset)

            selectionIndicator(height: tileHeight)
                .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: visibleHeight, alignment: .top)
        .clipped()
    }

    private func selectionIndicator(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.yellow, lineWidth: 3)
            .frame(height: height + 4)
            .shadow(color: .yellow.opacity(0.5), radius: 4)
    }

    private var spinButton: some View {
        Button {
            spin()
        } label: {
            Text(viewModel.isSpinning ? "Spinning..." : "SPIN!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 150, height: 50)
                .background(viewModel.isSpinning ? Color.gray : Color.green)
                .clipShape(Capsule())
        }
        .disabled(viewModel.isSpinning)
    }

    // MARK: - Private Helpers

    private func spin() {
        guard !viewModel.isSpinning else { return }

        let targetIndex = Int.random(in: 0..<prizes.count)
        let config = SpinConfiguration(
            targetPrizeIndex: targetIndex,
            numberOfRotations: 3,
            duration: 4.0
        )
        viewModel.spin(with: config)
    }

    // MARK: - Public Helpers

    /// Starts the wheel spinning to land on the specified prize.
    /// - Parameters:
    ///   - targetPrizeIndex: The index of the prize to land on.
    ///   - numberOfRotations: How many full cycles before stopping.
    ///   - duration: The total animation duration.
    func spin(
        to targetPrizeIndex: Int,
        numberOfRotations: Int = 3,
        duration: TimeInterval = 4.0
    ) {
        let config = SpinConfiguration(
            targetPrizeIndex: targetPrizeIndex,
            numberOfRotations: numberOfRotations,
            duration: duration
        )
        viewModel.spin(with: config)
    }

    /// Whether the wheel is currently spinning.
    var isSpinning: Bool {
        viewModel.isSpinning
    }
}

#Preview {
    let samplePrizes = [
        Prize(title: "🎁 Grand Prize", color: .purple, index: 0),
        Prize(title: "💰 $100", color: .green, index: 1),
        Prize(title: "🎫 Free Ticket", color: .blue, index: 2),
        Prize(title: "⭐ 50 Points", color: .orange, index: 3),
        Prize(title: "🎮 Game Token", color: .red, index: 4),
        Prize(title: "🍕 Free Pizza", color: .pink, index: 5),
        Prize(title: "☕ Coffee", color: .brown, index: 6),
        Prize(title: "🎵 Music Credit", color: .cyan, index: 7),
        Prize(title: "📱 App Premium", color: .indigo, index: 8),
        Prize(title: "🎬 Movie Pass", color: .mint, index: 9)
    ]

    PrizeWheelContainer(
        prizes: samplePrizes,
        onPrizeCrossedThreshold: { _ in },
        onSpinComplete: { prize in
            print("Won: \(prize.title)")
        }
    )
    .frame(width: 250)
    .padding()
}
