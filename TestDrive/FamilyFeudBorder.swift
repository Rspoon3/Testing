//
//  FamilyFeudBorder.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/31/24.
//

import SwiftUI

struct FamilyFeudBorder: Shape {
    let distance: CGFloat
    let halfDistance: CGFloat
    let height: CGFloat
    
    init(distance: CGFloat, height: CGFloat) {
        self.distance = distance
        self.halfDistance = distance / 2
        self.height = height
    }
    
    private func lerp(a: CGFloat, b: CGFloat, t: CGFloat) -> CGFloat {
        return a * (1 - t) + b * t
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let lineLength: CGFloat = rect.width * 0.15
        
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - halfDistance))
        path.addLine(to: CGPoint(x: rect.minX + lineLength, y: rect.midY - halfDistance))
        
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - lineLength, y: rect.midY - halfDistance),
            control: CGPoint(
                x: rect.midX,
                y: lerp(
                    a: rect.midY - halfDistance,
                    b: -(rect.size.height - distance) / 2,
                    t: height
                )
            )
        )
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - halfDistance))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + distance))
        
        // Bottom
        path.addLine(to: CGPoint(x: rect.maxX - lineLength, y: rect.midY + distance))
        
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + lineLength, y: rect.midY + distance),
            control: CGPoint(
                x: rect.midX,
                y: lerp(
                    a: rect.midY - halfDistance,
                    b: (rect.size.height - distance) / 2,
                    t: height
                )
            )
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + distance))
        path.closeSubpath()
        
        
        return path
    }
}

#Preview {
    @Previewable @State var distance: CGFloat = 0
    @Previewable @State var height: CGFloat = 0.5
    
    VStack {
        Slider(value: $distance, in: 0...100)
        Slider(value: $height, in: 0...1)
        
        FamilyFeudBorder(
            distance: distance,
            height: height
        )
        .stroke(Color.blue, lineWidth: 4)
        .frame(width: 300, height: 300)
        .border(Color.black)
        .padding()
        .overlay {
            Text(height.description)
        }
    }
}
