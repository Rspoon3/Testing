//
//  GlowingNumber2.swift
//  Testing
//
//  Created by Ricky on 11/17/24.
//

import SwiftUI

struct GlowingNumber2: View {
    @State private var position: CGPoint = .zero
    private let number: Int = Int.random(in: 1...99)
    private let color: Color = Color.random()
    private let animationDuration: Double = Double.random(in: 5...10)

    var body: some View {
        Text("\(number)")
            .font(.system(size: CGFloat.random(in: 40...80), weight: .bold))
            .foregroundColor(color.opacity(0.8))
            .blur(radius: Double.random(in: 3...10))
            .position(position) // Use `position` modifier
            .onAppear {
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height

                // Initial random position
                position = CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight)
                )

                // Start animation
                withAnimation(
                    Animation.easeInOut(duration: animationDuration)
                        .repeatForever(autoreverses: true)
                ) {
                    position = CGPoint(
                        x: CGFloat.random(in: 0...screenWidth),
                        y: CGFloat.random(in: 0...screenHeight)
                    )
                }
            }
    }
}


#Preview {
    GlowingNumber2()
}
