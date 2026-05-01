//
//  MovingNumbers.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct MovingNumbersLeftToRight: View {
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
                    let xPosition = basePosition + backAndForthProgress * 200
                    
                    // Vertical position for each number
                    let yPosition = spacing * CGFloat(index + 1)
                    
                    // Draw the number
                    let number = numbers[index]
                    let color = colors[index % colors.count]
                    let text = Text("\(number)")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(color.opacity(0.8))
                    
                    // Draw the number at the current position
                    context.draw(text, at: CGPoint(x: xPosition, y: yPosition))
                }
            }
        }
        .background(Color.white) // Background for better visibility
    }
}

#Preview {
    MovingNumbersLeftToRight()
}


extension UIColor {
    static func random(alpha: CGFloat = 1.0) -> UIColor {
        let r = CGFloat.random(in: 0...1)
        let g = CGFloat.random(in: 0...1)
        let b = CGFloat.random(in: 0...1)
        
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }
    
    static var lightRandom: UIColor {
        random(alpha: 0.6)
    }
}

