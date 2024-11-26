//
//  MovingCanvasView.swift
//  Testing
//
//  Created by Ricky on 11/17/24.
//

import SwiftUI

struct MovingCanvasView: View {
    @State private var targetPositions: [CGPoint] = []
    @State private var scales: [CGFloat] = []
    @State private var isReversing = false
    @State private var lastUpdate = Date()

    private let circleCount = 20
    private let circleSize: CGFloat = 40
    private let animationDuration: TimeInterval = 4

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.periodic(from: .now, by: 1 / 30)) { timeline in
                Canvas { context, size in
                    // Ensure the target positions are initialized correctly
                    guard targetPositions.count == circleCount else { return }

                    // Time elapsed and calculate progress
                    let elapsedTime = timeline.date.timeIntervalSince(lastUpdate)
                    var progress = elapsedTime.truncatingRemainder(dividingBy: animationDuration) / animationDuration
                    if isReversing { progress = 1 - progress }
                    
//                    let scale = 1.0 + (progress * 0.5) // Scale from 1.0 to 1.5
//                    let scale = 1.0 + (progress * 2.5) // Scale from 1.0 to 3.5

                    // Draw circles moving to random positions
                    for i in 0..<circleCount {
                        let startX = size.width / 2
                        let startY = size.height / 2
                        let targetX = targetPositions[i].x
                        let targetY = targetPositions[i].y
                        
                        let currentX = startX + (targetX - startX) * progress
                        let currentY = startY + (targetY - startY) * progress
                        
                        let currentPosition = CGPoint(x: currentX, y: currentY)
                        
                        // Random number and font
                        let text = Text("\(99)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(Color.red.opacity(0.8))
                        
                        context.draw(text, at: currentPosition)
                    }
                }
                .onChange(of: timeline.date) { date in
                    let elapsed = date.timeIntervalSince(lastUpdate)
                    if elapsed >= animationDuration {
                        isReversing.toggle()
                        if !isReversing {
                            // Generate new random positions after a complete forward and reverse cycle
                            targetPositions = generateRandomPositions(size: geometry.size)
                        }
                        lastUpdate = date
                    }
                }
                .onAppear {
                    // Initialize target positions when the view appears
                    targetPositions = generateRandomPositions(size: geometry.size)
                }
            }
        }
        .background(Color.white)
    }

    private func generateRandomPositions(size: CGSize) -> [CGPoint] {
        (0..<circleCount).map { _ in
            CGPoint(
                x: CGFloat.random(in: circleSize / 2...(size.width - circleSize / 2)),
                y: CGFloat.random(in: circleSize / 2...(size.height - circleSize / 2))
            )
        }
    }
}

#Preview {
    MovingCanvasView()
}
