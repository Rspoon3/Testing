//
//  UnfurlingCircleSliderView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 12/1/25.
//

import SwiftUI

struct BallsToFullCircleView: View {
    @State private var progress: CGFloat = 0.0   // 0 = line, 1 = circle

    let ballCount = 21   // Must be odd for a center ball

    var body: some View {
        VStack {
            GeometryReader { geo in
                let size   = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = size * 0.35

                let middleIndex = (ballCount - 1) / 2
                let lineLength  = radius * 2.0

                ZStack {
                    // Guide circle
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                        .foregroundStyle(.gray.opacity(0.4))
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)

                    ForEach(0..<ballCount, id: \.self) { index in
                        // t: -1 ... 1  (middle is 0)
                        let t = CGFloat(index - middleIndex) / CGFloat(middleIndex)

                        // START: horizontal line at top
                        let startX = center.x + t * (lineLength / 2)
                        let startY = center.y - radius

                        // END: full circle, with center ball at angle -π/2 (top)
                        //
                        // Spread angles evenly around circle:
                        //   t = 0 → angle = -π/2 (top)
                        //   t = -1 → angle = -π/2 - π (left/bottom region)
                        //   t =  1 → angle = -π/2 + π (right/bottom region)
                        //
                        // Full spread = 2π
                        let angle = (-.pi / 2) + (t * .pi)

                        let endX = center.x + radius * cos(angle)
                        let endY = center.y + radius * sin(angle)

                        // Interpolate based on slider
                        let x = startX + (endX - startX) * progress
                        let y = startY + (endY - startY) * progress

                        Circle()
                            .fill(.blue)
                            .frame(width: 14, height: 14)
                            .position(x: x, y: y)
                    }
                }
            }
            .padding()

            Slider(value: $progress, in: 0...1)
                .padding(.horizontal)

            Text(String(format: "%.2f", progress))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    BallsToFullCircleView()
}
