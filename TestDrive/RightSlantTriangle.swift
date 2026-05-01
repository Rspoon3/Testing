//
//  RightSlantTriangle.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/3/25.
//

import SwiftUI

struct RightSlantTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))      // top-left
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))   // top-right
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))   // bottom-left
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    HStack(spacing: 0) {
        Rectangle().foregroundStyle(.red)
        RightSlantTriangle()
    }
    .frame(height: 56)
}
