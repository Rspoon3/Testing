//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

/// Main content view demonstrating the PrizeWheel component.
struct ContentView: View {
    @State private var lastWonPrize: Prize?

    private let prizes: [Prize] = [
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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            headerView

            PrizeWheelContainer(
                prizes: prizes,
                tileHeight: 60,
                tileSpacing: 4,
                onPrizeCrossedThreshold: { _ in
                    triggerHapticTick()
                },
                onSpinComplete: { prize in
                    handleSpinComplete(prize)
                }
            )
            .frame(width: 250)

            resultView
        }
        .padding()
    }

    // MARK: - Private Views

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("🎰 Prize Wheel")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Spin to win!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var resultView: some View {
        if let result = lastWonPrize {
            VStack(spacing: 8) {
                Text("🎉 You won!")
                    .font(.headline)

                Text(result.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(result.color)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Private Helpers

    private func handleSpinComplete(_ prize: Prize) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            lastWonPrize = prize
        }

        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    private func triggerHapticTick() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}

#Preview {
    ContentView()
}
