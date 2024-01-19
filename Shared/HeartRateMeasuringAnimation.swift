//
//  HeartRateMeasuringAnimation.swift
//  Testing
//
//  Created by Richard Witherspoon on 1/16/24.
//

import SwiftUI

struct HeartRateMeasuringAnimation: View {
    @State private var measuring = false
    let blue = Color(#colorLiteral(red: 0, green: 0.3725490196, blue: 1, alpha: 1))
    let red = Color(#colorLiteral(red: 1, green: 0, blue: 0, alpha: 1))
    let dashPhase: CGFloat = 83 / 3.2
    
    var body: some View {
        HeartIcon()
            .stroke(
                style:
                    StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        lineJoin: .round,
                        miterLimit: 0,
                        dash: [150 / 3.2, 15/3.2],
                        dashPhase: measuring ? -dashPhase : dashPhase
                    )
            )
            .frame(width: 20, height: 20)
            .onAppear {
                withAnimation(.linear(duration: 2.5)
                    .repeatForever(autoreverses: false)) {
                        measuring.toggle()
                    }
            }
            .foregroundStyle(
                .angularGradient(
                    colors: [blue, red, blue],
                    center: .center,
                    startAngle: .degrees(measuring ? 360 : 0),
                    endAngle: .degrees(measuring ? 720 : 360)
                )
            )
    }
}

#Preview {
    HeartRateMeasuringAnimation()
}
