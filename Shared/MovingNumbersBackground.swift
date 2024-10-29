//
//  MovingNumbersBackground.swift
//  Testing
//
//  Created by Ricky on 10/29/24.
//


import SwiftUI

struct MovingNumbersBackground: View {
    let numberCount = 20

    var body: some View {
        ZStack {
            ForEach(0..<numberCount, id: \.self) { _ in
                GlowingNumber()
                    .position(randomPosition())
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 5...10))
                            .repeatForever(autoreverses: true)
                    )
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea()
    }
    
    private func randomPosition() -> CGPoint {
        // Random starting position within the screen bounds
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        return CGPoint(
            x: CGFloat.random(in: 0...screenWidth),
            y: CGFloat.random(in: 0...screenHeight)
        )
    }
}

struct GlowingNumber: View {
    @State private var offset: CGSize = .zero
    private let number: Int = Int.random(in: 1...99) // Random number for each instance
    private let color: Color = Color.random()

    var body: some View {
        Text("\(number)")
            .font(.system(size: CGFloat.random(in: 40...80), weight: .bold))
            .foregroundColor(color.opacity(0.8))
            .blur(radius: Double.random(in: 3...10))
            .offset(offset)
            .onAppear {
                // Animate the number to move around gently
                withAnimation(
                    Animation.easeInOut(duration: Double.random(in: 5...10))
                        .repeatForever(autoreverses: true)
                ) {
                    offset = CGSize(
                        width: CGFloat.random(in: -50...50),
                        height: CGFloat.random(in: -50...50)
                    )
                }
            }
    }
}
