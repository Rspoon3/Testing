//
//  CircularProgressView.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/15/25.
//

import SwiftUI

struct CircularProgressView: View {
    var progress: Double // 0.0 to 1.0
    var title: String
    var valueText: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.2)
                    .foregroundColor(.gray)

                Circle()
                    .trim(from: 0.0, to: min(progress, 1.0))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .foregroundColor(.accentColor)
                    .rotationEffect(.degrees(-90))

                Image(systemName: systemImage)
                    .font(.system(size: 16))
            }
            .frame(width: 50, height: 50)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                Text(valueText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
