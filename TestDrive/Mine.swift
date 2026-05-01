//
//  Mine.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct Mine: View {
    @State private var isMoving = false
    @State private var boarderOpacity: CGFloat = 0
    @State private var boarderAngle: CGFloat = 90
    private let cornerRadius: CGFloat = 8
    
    var body: some View {
        Button("Get Started") {
        }
        .padding(16)
        .background(Color.white)
        .foregroundStyle(.purple)
        .cornerRadius(cornerRadius)
        .overlay {
            GradientTest(
                rotationDuration: 1.5,
                pauseDuration: 3,
                maxSliceWidth: 90,
                convergenceAngle: 0,
                opacityAnimationPercentage: 0.25
            )
            .rotationEffect(.degrees(-90))
            .mask(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(style: StrokeStyle(lineWidth: 3)) // inside stroke
            )
        }
        .padding(24)
        .background(Color.purple)
    }
}

#Preview {
    Mine()
}
