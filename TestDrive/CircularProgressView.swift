//
//  CircularProgressView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 9/24/25.
//

import SwiftUI

struct CircularProgressView: View, Animatable {
    var progress: Double
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                .padding(1.5)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    colorForProgress(progress),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(1.5)
        }
    }

    private func colorForProgress(_ progress: Double) -> Color {
        if progress >= 0.5 {
            // Green to Yellow (1.0 to 0.5)
            let t = (progress - 0.5) / 0.5
            return Color(
                red: 1.0 - t,
                green: 1.0,
                blue: 0.0
            )
        } else {
            // Yellow to Red (0.5 to 0.0)
            let t = progress / 0.5
            return Color(
                red: 1.0,
                green: t,
                blue: 0.0
            )
        }
    }
}

#Preview {
    ZStack {
        Color.orange
        VStack {
            CircularProgressView(progress: 0)
            CircularProgressView(progress: 0.2)
            CircularProgressView(progress: 0.4)
            CircularProgressView(progress: 0.6)
            CircularProgressView(progress: 1)
        }
    }
}
