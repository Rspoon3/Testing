//
//  SettingsView.swift
//  TestDrive (iOS)
//
//  Created by Ricky Witherspoon on 8/28/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var showPurpleScreen = false
    @State private var hasNavigatedToPurpleScreen = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This tab will navigate to purple screen on appear")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationDestination(isPresented: $showPurpleScreen) {
                PurpleSheetView()
            }
            .task {
                guard !hasNavigatedToPurpleScreen else { return }
                try? await Task.sleep(for: .seconds(1))
                hasNavigatedToPurpleScreen = true
                // Navigate to purple screen manually
                showPurpleScreen = true
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DeepLinkQueue.shared)
}
