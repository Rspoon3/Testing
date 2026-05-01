//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var isMoving = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 160, height: 54)
                .foregroundStyle(.indigo.gradient)
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 5,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: [40, 400],
                        dashPhase: isMoving ? 220 : -220
                    )
                )
                .frame(width: 160, height: 58)
                .foregroundStyle(
                    Color.red
                )
            
            Button("Get Started") {
            }
            .foregroundColor(.white)
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                isMoving.toggle()
            }
        }
    }
}

#Preview {
    ContentView()
}
