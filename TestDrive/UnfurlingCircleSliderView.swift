//
//  UnfurlingCircleSliderView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 12/1/25.
//


import SwiftUI

import SwiftUI

struct BallsToCircleView: View {
    @State private var progress: CGFloat = 0.0   // 0 = line, 1 = circle
    
    let ballCount = 20
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = size * 0.35
                
                ZStack {
                    // Optional: faint circle guide
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                        .foregroundStyle(.gray.opacity(0.4))
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                    
                    ForEach(0..<ballCount, id: \.self) { index in
                        let fraction = CGFloat(index) / CGFloat(ballCount)
                        let angle = 2 * .pi * fraction
                        
                        // End position: on the circle
                        let circleX = center.x + radius * cos(angle)
                        let circleY = center.y + radius * sin(angle)
                        
                        // Start position: all on a horizontal line
                        // Here we spread them along a line above the circle
                        let lineY = center.y - radius
                        let lineX = geo.size.width * (0.15 + 0.7 * fraction) // left→right with padding
                        
                        // Interpolated position based on progress
                        let x = lineX + (circleX - lineX) * progress
                        let y = lineY + (circleY - lineY) * progress
                        
                        Circle()
                            .fill(.blue)
                            .frame(width: 14, height: 14)
                            .position(x: x, y: y)
                    }
                }
            }
            .padding()
            
            // Slider controls the morph
            VStack {
                Slider(value: $progress, in: 0...1)
                Text(String(format: "Progress: %.2f", progress))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    BallsToCircleView()
}
