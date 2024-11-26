//
//  MovingNumbersBackgroundV2.swift
//  Testing
//
//  Created by Ricky on 11/17/24.
//

import SwiftUI

struct MovingNumbersBackgroundV2: View {
    let numberCount = 2
    private let numbers: [Int] = (1...20).map { _ in Int.random(in: 1...99) }
    private let colors: [Color] = (1...20).map { _ in Color.random() }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let screenWidth = size.width
                let screenHeight = size.height
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for index in 0..<numberCount {
                    // Fixed 4-second duration for each loop
                    let animationDuration: Double = 4
                    let cycleProgress = (time + Double(index)) / animationDuration
                    let normalizedProgress = cycleProgress.truncatingRemainder(dividingBy: 1) // Wrap around 0...1
                    
                    // Random starting and ending positions
                    let startPosition = CGPoint(
                        x: CGFloat.random(in: 0...screenWidth),
                        y: CGFloat.random(in: 0...screenHeight)
                    )
                    let endPosition = CGPoint(
                        x: CGFloat.random(in: 0...screenWidth),
                        y: CGFloat.random(in: 0...screenHeight)
                    )
                    
                    // Interpolated position based on normalized progress
                    let currentPosition = CGPoint(
                        x: startPosition.x + normalizedProgress * (endPosition.x - startPosition.x),
                        y: startPosition.y + normalizedProgress * (endPosition.y - startPosition.y)
                    )
                    
                    // Draw the number
                    let number = numbers[index]
                    let color = colors[index]
                    let text = Text("\(number)")
                        .font(.system(size: CGFloat.random(in: 40...80), weight: .bold))
                        .foregroundColor(color.opacity(0.8))
                    
                    context.draw(text, at: currentPosition)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea()
    }
}

#Preview {
    MovingNumbersBackgroundV2()
}
