//
//  LineAndHalfCircleShape.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/31/24.
//

import SwiftUI

struct LineAndHalfCircleShape: Shape {
    var insetAmount = 0.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var maxY = rect.maxY
        
        // Draw horizontal line
        let lineLength: CGFloat = rect.width * 0.15
        path.move(to: CGPoint(x: rect.minX, y: maxY))
        path.addLine(to: CGPoint(x: rect.minX + lineLength, y: maxY))
        
        let radius = rect.width / 2 - lineLength
        // Draw half circle
        path.addArc(
            center: CGPoint(
                x: rect.minX + lineLength + radius,
                y: maxY
            ),
            radius: radius - insetAmount,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: rect.maxX, y: maxY))
        
        return path
    }
}
