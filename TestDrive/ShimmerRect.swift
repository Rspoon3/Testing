//
//  ShimmerRect.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/3/25.
//

import SwiftUI

struct ShimmerRect: View {
    private let cornerRadius: CGFloat = 22
    @State private var animate = false
    @State private var opacity = 0.0

    var body: some View {
        Rectangle()
            .foregroundStyle(.purple)
            .frame(
                width: 124,
                height: 56,
                alignment: .leading
            )
            .background(Color.darkPurple)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                AngularGradient(
                    gradient: Gradient(
                        stops: [
                            .init(
                                color: .purple,
                                location: 0
                            ),
                            .init(
                                color: .purple,
                                location: 0.76
                            ),
                            .init(
                                color: .white,
                                location: 1
                            )
                        ]
                    ),
                    center: .center,
                    angle: .degrees(animate ? 450 : 90)
                )
                .opacity(opacity)
                .mask(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(style: StrokeStyle(lineWidth: 3))
                )
            }
            .onAppear {
                withAnimation(.linear(duration: 1.2)) {
                    animate.toggle()
                }
                
                Task {
                    withAnimation(.linear(duration: 0.25)) {
                        opacity = 1
                    }
                    try? await Task.sleep(for: .milliseconds(950))
                    
                    withAnimation(.linear(duration: 0.25)) {
                        opacity = 0
                    }
                }
            }
    }
}

#Preview {
    ShimmerRect()
}
