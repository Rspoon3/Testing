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
    @State private var showDeleteConfirmation: Bool = false
    
    
    @AppStorage("score") private var score: Double = 0
    @AppStorage("totalSwipes") private var totalSwipes = 0
    @AppStorage("correctSwipes") private var correctSwipes = 0
    @AppStorage("currentIndex") private var currentIndex = 1
    @AppStorage("nextNumber") private var nextNumber = 4
    @AppStorage("currentStreak") private var currentStreak = 0
    @AppStorage("maxStreak") private var maxStreak = 0

    func resetSwipes() {
        score = 0
        totalSwipes = 0
        correctSwipes = 0
        currentIndex = 0
        nextNumber = 4
        currentStreak = 0
        maxStreak = 0
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            
            SettingsItemButton(
                title: "Reset Swipe Count",
                symbol: .arrowCounterclockwiseCircleFill,
                gradientColors: [.red, .orange],
                shadowColor: .red.opacity(0.5),
                isAnimating: isAnimating
            ) {
                showDeleteConfirmation = true
            }
            .confirmationDialog(
                "Are you sure you want to reset you swipes?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    resetSwipes()
                }
            }
            
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
            
            SettingsItemButton(
                title: "Share With a Friend",
                symbol: .share,
                gradientColors: [
                    .yellow.opacity(0.8),
                    .orange.opacity(0.8),
                    .gold.opacity(0.9)
                ],
                shadowColor: .orange.opacity(0.5),
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

private extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0) // Custom gold color
}

#Preview {
    SettingsView()
}
