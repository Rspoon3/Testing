//
//  GlowingOrbsBackground.swift
//  Testing
//
//  Created by Ricky on 10/29/24.
//

import SwiftUI
import SwiftUI

struct GlowingOrbsBackground: View {
    let orbCount = 10

    var body: some View {
        ZStack {
            ForEach(0..<orbCount, id: \.self) { _ in
                GlowingOrb()
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

struct GlowingOrb: View {
    @State private var offset: CGSize = .zero
    private let color: Color = Color.random()

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [color.opacity(0.8), color.opacity(0.2)]),
                    center: .center,
                    startRadius: 5,
                    endRadius: 100
                )
            )
            .frame(width: CGFloat.random(in: 40...150), height: CGFloat.random(in: 40...150))
            .blur(radius: Double.random(in: 5...16))
            .scaleEffect(1.1)
            .offset(offset)
            .onAppear {
                // Animate the orb to move around gently
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

// Extension for generating random colors
extension Color {
    static func random() -> Color {
        return Color(
            red: Double.random(in: 0.3...1),
            green: Double.random(in: 0.3...1),
            blue: Double.random(in: 0.3...1)
        )
    }
}
