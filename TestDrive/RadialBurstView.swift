//
//  RadialBurstView.swift
//  Testing
//
//  Created by Ricky on 3/4/25.
//

import SwiftUI

struct RadialBurstView: View {
    @State private var rayCount = 50
    @State private var rotate = false
    let colors = [Color.purple, Color.purple.opacity(0.5)]

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let maxRadius = sqrt(pow(geometry.size.width, 2) + pow(geometry.size.height, 2)) / 2
            
            ZStack {
                ForEach(0..<rayCount, id: \.self) { i in
                    let angle1 = Double(i) / Double(rayCount) * 2 * .pi
                    let angle2 = Double(i + 1) / Double(rayCount) * 2 * .pi
                    
                    let start1 = CGPoint(
                        x: center.x + CGFloat(cos(angle1)) * maxRadius,
                        y: center.y + CGFloat(sin(angle1)) * maxRadius
                    )
                    
                    let start2 = CGPoint(
                        x: center.x + CGFloat(cos(angle2)) * maxRadius,
                        y: center.y + CGFloat(sin(angle2)) * maxRadius
                    )

                    Path { path in
                        path.move(to: center)
                        path.addLine(to: start1)
                        path.addLine(to: start2)
                        path.closeSubpath()
                    }
                    .fill(colors[i.isMultiple(of: 2) ? 0 : 1])
                }
            }
            .drawingGroup()
//            .rotationEffect(.degrees(rotate ? 360 : 0))
//            .onAppear {
//                withAnimation(.linear(duration: 50).repeatForever(autoreverses: false)) {
//                    rotate = true
//                }
//            }
        }
        .ignoresSafeArea(edges: .all)
        .overlay {
            Stepper("Rays: \(rayCount)", value: $rayCount, in: 0...100)
        }
    }
}

#Preview {
    RadialBurstView()
}
