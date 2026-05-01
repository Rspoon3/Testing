//
//  GooView.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/13/25.
//

import SwiftUI
import Foundation

struct GooView: View {
    @State private var centerPosition: CGPoint = CGPoint(x: 200, y: 200)
    @State private var dragPosition: CGPoint = CGPoint(x: 200, y: 200)
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            // Goo shape
            GooShape(
                centerPoint: centerPosition,
                dragPoint: dragPosition,
                isDragging: isDragging
            )
            .fill(Color.blue)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragPosition)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragPosition = value.location
                    }
                    .onEnded { _ in
                        isDragging = false
                        // Snap back to center
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            dragPosition = centerPosition
                        }
                    }
            )
        }
        .onAppear {
            centerPosition = CGPoint(x: 200, y: 200)
            dragPosition = centerPosition
        }
    }
}

struct GooShape: Shape {
    let centerPoint: CGPoint
    let dragPoint: CGPoint
    let isDragging: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let distance = sqrt(pow(dragPoint.x - centerPoint.x, 2) + pow(dragPoint.y - centerPoint.y, 2))
        
        if distance < 5 {
            // When close, just draw a circle
            path.addEllipse(in: CGRect(
                x: centerPoint.x - 30,
                y: centerPoint.y - 30,
                width: 60,
                height: 60
            ))
        } else {
            // Create stretchy goo effect
            let radius: CGFloat = 30
            let stretchFactor = min(distance / 100, 2.0)
            
            // Calculate the angle between center and drag point
            let angle = atan2(dragPoint.y - centerPoint.y, dragPoint.x - centerPoint.x)
            let perpAngle = angle + .pi / 2
            
            // Create control points for smooth curves
            let midX = (centerPoint.x + dragPoint.x) / 2
            let midY = (centerPoint.y + dragPoint.y) / 2
            
            // Calculate neck width (gets thinner with distance)
            let neckRadius = radius * (1 - stretchFactor * 0.4)
            
            // Start from center circle
            let centerTop = CGPoint(
                x: centerPoint.x + cos(perpAngle) * radius,
                y: centerPoint.y + sin(perpAngle) * radius
            )
            let centerBottom = CGPoint(
                x: centerPoint.x - cos(perpAngle) * radius,
                y: centerPoint.y - sin(perpAngle) * radius
            )
            
            // Neck points
            let neckTop = CGPoint(
                x: midX + cos(perpAngle) * neckRadius,
                y: midY + sin(perpAngle) * neckRadius
            )
            let neckBottom = CGPoint(
                x: midX - cos(perpAngle) * neckRadius,
                y: midY - sin(perpAngle) * neckRadius
            )
            
            // Drag circle points
            let dragTop = CGPoint(
                x: dragPoint.x + cos(perpAngle) * radius,
                y: dragPoint.y + sin(perpAngle) * radius
            )
            let dragBottom = CGPoint(
                x: dragPoint.x - cos(perpAngle) * radius,
                y: dragPoint.y - sin(perpAngle) * radius
            )
            
            // Draw the goo shape
            path.move(to: centerTop)
            
            // Top curve from center to neck
            path.addQuadCurve(to: neckTop, control: CGPoint(
                x: (centerTop.x + neckTop.x) / 2,
                y: (centerTop.y + neckTop.y) / 2
            ))
            
            // Top curve from neck to drag point
            path.addQuadCurve(to: dragTop, control: CGPoint(
                x: (neckTop.x + dragTop.x) / 2,
                y: (neckTop.y + dragTop.y) / 2
            ))
            
            // Arc around drag point
            path.addArc(
                center: dragPoint,
                radius: radius,
                startAngle: Angle(radians: perpAngle),
                endAngle: Angle(radians: perpAngle + .pi),
                clockwise: false
            )
            
            // Bottom curve from drag point to neck
            path.addQuadCurve(to: neckBottom, control: CGPoint(
                x: (dragBottom.x + neckBottom.x) / 2,
                y: (dragBottom.y + neckBottom.y) / 2
            ))
            
            // Bottom curve from neck to center
            path.addQuadCurve(to: centerBottom, control: CGPoint(
                x: (neckBottom.x + centerBottom.x) / 2,
                y: (neckBottom.y + centerBottom.y) / 2
            ))
            
            // Arc around center point
            path.addArc(
                center: centerPoint,
                radius: radius,
                startAngle: Angle(radians: perpAngle + .pi),
                endAngle: Angle(radians: perpAngle),
                clockwise: false
            )
            
            path.closeSubpath()
        }
        
        return path
    }
}

#Preview {
    GooView()
}
