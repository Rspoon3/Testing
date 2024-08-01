//
//  HalfCircleDots.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/31/24.
//

import SwiftUI

struct HalfCircleDots: View {
    let dotCount = 18
    let dotSize: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            let lineLength: CGFloat = geometry.size.width * 0.15
            let radius = geometry.size.width / 2 - lineLength
            let center = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height
            )
            
            // Leading
            Circle()
                .fill(Color.red)
                .frame(
                    width: dotSize,
                    height: dotSize
                )
                .position(
                    x: dotSize / 2,
                    y: center.y
                )
            
            Circle()
                .fill(Color.red)
                .frame(
                    width: dotSize,
                    height: dotSize
                )
                .position(
                    x: lineLength / 2,
                    y: center.y
                )
            
            // Arc
            ForEach(0..<dotCount, id:  \.self) { index in
                let angle = Angle.degrees(Double(index) / Double(dotCount - 1) * 180)
                let x = center.x + radius * cos(CGFloat(angle.radians))
                let y = center.y - radius * sin(CGFloat(angle.radians))

                Circle()
                    .fill(Color.red)
                    .frame(
                        width: dotSize,
                        height: dotSize
                    )
                    .position(x: x, y: y)
            }
            
            // Trailing
            Circle()
                .fill(Color.red)
                .frame(
                    width: dotSize,
                    height: dotSize
                )
                .position(
                    x: geometry.size.width - lineLength / 2,
                    y: center.y
                )
            
            Circle()
                .fill(Color.red)
                .frame(
                    width: dotSize,
                    height: dotSize
                )
                .position(
                    x: geometry.size.width - dotSize / 2,
                    y: center.y
                )

        }
    }
}
