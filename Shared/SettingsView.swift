//
//  SettingsView.swift
//  Testing
//
//  Created by Ricky on 11/16/24.
//

import SwiftUI
import RSWTools

struct SettingsView: View {
    @State private var isAnimating: Bool = false
    
    var body: some View {
        
        VStack(spacing: 10) {
            Spacer()
            SettingsItemButton(
                title: "Reset Swipe Count",
                symbol: .arrowCounterclockwiseCircleFill,
                gradientColors: [.red, .orange],
                shadowColor: .red.opacity(0.5),
                isAnimating: isAnimating
            ) {}
            
            SettingsItemButton(
                title: "Send Feedback",
                symbol: .paperplaneFill,
                gradientColors: [.blue, .purple],
                shadowColor: .blue.opacity(0.5),
                isAnimating: isAnimating
            ) {}
            
            SettingsItemButton(
                title: "Leave a Review",
                symbol: .starFill,
                gradientColors: [.mint, .teal, .cyan.opacity(0.8)],
                shadowColor: .teal.opacity(0.3),
                isAnimating: isAnimating
            ) {}
            
            Spacer()
            SettingsMadeBy(appID: 1)
        }
        .onAppear {
            isAnimating = true
        }
    }
}


#Preview {
    SettingsView()
}

struct LeaveReviewButton: View {
    @State private var isAnimating = false

    var body: some View {
        Button(action: {
            // Add action for leaving a review
            print("Navigate to review page")
        }) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title)
                    .foregroundColor(.white)

                Text("Leave a Review")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.mint, Color.teal, Color.cyan.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.teal.opacity(0.3), radius: 10, x: 0, y: 5)
            .scaleEffect(isAnimating ? 1.05 : 1.0)
        }
        .padding()
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
