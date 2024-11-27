//
//  MovingNumbers.swift
//  Testing
//
//  Created by Ricky on 11/27/24.
//

import SwiftUI

struct MovingNumbers: View {
    private let numberCount = 5
    private let numbers: [Int] = (1...5).map { _ in Int.random(in: 1...99) }
    private let colors: [Color] = [.red, .blue, .green, .orange, .purple]
    private let animationDuration: Double = 2.0 // Duration for one full back-and-forth motion
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let screenWidth = size.width
                let screenHeight = size.height
                let spacing = screenHeight / CGFloat(numberCount + 1)
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for index in 0..<numberCount {
                    // Calculate normalized progress (0 to 1 and back)
                    let progress = (time / animationDuration).truncatingRemainder(dividingBy: 1)
                    let backAndForthProgress = progress < 0.5
                        ? progress * 2 // 0 to 1 for the first half
                        : (1 - progress) * 2 // 1 to 0 for the second half
                    
                    // Calculate x position (linear back-and-forth)
                    let basePosition: CGFloat = screenWidth / 2
                    let xPosition = basePosition + backAndForthProgress * 100
                    
                    // Calculate blur amount based on x position
                    let blurAmount = backAndForthProgress * 10
                    
                    // Calculate scale factor
                    let scaleFactor = 1 + backAndForthProgress * 0.5
                    
                    // Vertical position for each number
                    let yPosition = spacing * CGFloat(index + 1)
                    
                    // Render the number text
                    let number = numbers[index]
                    let color = colors[index % colors.count]
                    let attributedString = AttributedString("\(number)")
                    
                    // Draw the text with a shadow to simulate blur
                    let resolvedText = context.resolve(Text(attributedString)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(color.opacity(0.8)))
                    
                    context.drawLayer { layerContext in
                        layerContext.addFilter(.blur(radius: blurAmount))
                        
                        // Apply scaling by transforming the context
                        layerContext.translateBy(x: xPosition, y: yPosition)
                        layerContext.scaleBy(x: scaleFactor, y: scaleFactor)
                        layerContext.translateBy(x: -xPosition, y: -yPosition)
                        
                        layerContext.draw(resolvedText, at: CGPoint(x: xPosition, y: yPosition))
                    }
                }
            }
        }
        .background(Color.white) // Background for better visibility
    }
}
