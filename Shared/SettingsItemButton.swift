//
//  SettingsItemButton.swift
//  Testing
//
//  Created by Ricky on 11/17/24.
//

import SwiftUI
import SFSymbols

struct SettingsItemButton: View {
    let title: String
    let symbol: SFSymbol
    let gradientColors: [Color]
    let shadowColor: Color
    let isAnimating: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 16) {
                Image(symbol: symbol)
                    .font(.title)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding()
            .frame(width: 300)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
            .scaleEffect(isAnimating ? 1.05 : 1.0)
        }
        .padding()
        .animation(
            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
            value: isAnimating
        )
    }
}

#Preview {
    @Previewable @State var isAnimating = false
    
    SettingsItemButton(
        title: "Leave a Review",
        symbol: .starFill,
        gradientColors: [Color.mint, Color.teal, Color.cyan.opacity(0.8)],
        shadowColor: .teal.opacity(0.3),
        isAnimating: isAnimating
    ) {}
    .onAppear {
        isAnimating = true
    }
}
