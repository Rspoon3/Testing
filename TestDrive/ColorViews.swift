//
//  ColorViews.swift
//  TestDrive
//
//  Created by Claude on 8/28/25.
//

import SwiftUI

struct ColorScreen: View {
    let colorName: String
    
    var body: some View {
        ZStack {
            color(for: colorName)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(colorName.capitalized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(textColor(for: colorName))
                
                Text("Navigation Destination")
                    .font(.headline)
                    .foregroundColor(textColor(for: colorName))
                
                Button("Back to Home") {
                    NavigationCoordinator.shared.popToRoot()
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(10)
            }
        }
        .navigationTitle(colorName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ColorSheet: View {
    let colorName: String
    
    var body: some View {
        NavigationView {
            ZStack {
                color(for: colorName)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text(colorName.capitalized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(textColor(for: colorName))
                    
                    Text("Sheet Presentation")
                        .font(.headline)
                        .foregroundColor(textColor(for: colorName))
                    
                    Button("Dismiss") {
                        NavigationCoordinator.shared.dismissSheet()
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                }
            }
            .navigationTitle("\(colorName.capitalized) Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    NavigationCoordinator.shared.dismissSheet()
                }
            )
        }
    }
}

// Helper functions for color mapping
private func color(for name: String) -> Color {
    switch name.lowercased() {
    case "red":
        return .red
    case "blue":
        return .blue
    case "green":
        return .green
    case "yellow":
        return .yellow
    case "purple":
        return .purple
    case "orange":
        return .orange
    case "pink":
        return .pink
    case "cyan":
        return .cyan
    case "mint":
        return .mint
    case "indigo":
        return .indigo
    default:
        return .gray
    }
}

private func textColor(for colorName: String) -> Color {
    switch colorName.lowercased() {
    case "yellow", "cyan", "mint":
        return .black
    default:
        return .white
    }
}

#Preview {
    ColorScreen(colorName: "red")
}

#Preview {
    ColorSheet(colorName: "blue")
}