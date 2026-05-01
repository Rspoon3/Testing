//
//  InProgress.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct InProgress: View {
    @State private var isAnimating = false
    @State private var leadingProgress: CGFloat = 0
    @State private var trailingProgress: CGFloat = 0
    @State private var rotation: CGFloat = 0
    private let cornerRadius: CGFloat = 8
    
    var body: some View {
        ZStack {
            Button("Get Started") {
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(8)
            .foregroundStyle(.purple)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .trim(from: 0, to: leadingProgress - trailingProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.purple, location: 0),
                                .init(color: Color.purple, location: 0.8),
                                .init(color: Color.white.opacity(0.3), location: 1)
                            ]),
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .rotationEffect(.degrees(rotation + trailingProgress * 360))
            }
        }
        .padding(24)
        .background(Color.purple)
    }
}

#Preview {
    InProgress()
}
