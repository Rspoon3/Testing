//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    private let animationDuration = 4.0
    private let colors: [Color] = [
        .red,
        .blue,
        .green,
        .orange,
        .purple,
        .teal,
        .pink,
        .mint,
        .indigo,
        .cyan
    ]
    private var numberOfCircles: Int {
        colors.count
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Calculate elapsed time
                let currentTime = timeline.date.timeIntervalSinceReferenceDate
                let rawProgress = (currentTime.truncatingRemainder(dividingBy: animationDuration)) / animationDuration
                
                // Constants
                let extendedWidth = size.width + 50 // Extend width by circle size
                let circleSize: CGFloat = 50
                let spacing = size.height / CGFloat(numberOfCircles + 1) // Spacing between circles
                
                // Draw multiple circles
                for index in 0..<numberOfCircles {
                    // Calculate individual circle progress with offset
                    let phaseOffset = Double(index) * (animationDuration / Double(numberOfCircles))
                    let adjustedProgress = CGFloat((rawProgress + phaseOffset / animationDuration).truncatingRemainder(dividingBy: 1.0))
                    let xPosition = (adjustedProgress * extendedWidth) - 50
                    
                    // Vertical position
                    let yPosition = spacing * CGFloat(index + 1)
                    
                    // Draw the circle
                    let rect = CGRect(
                        x: xPosition,
                        y: yPosition - circleSize / 2,
                        width: circleSize,
                        height: circleSize
                    )
                    
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(colors[index % colors.count])
                    )
                }
            }
        }
        .background(Color.white) // Background for better visibility
    }
}
#Preview {
    ContentView()
}

