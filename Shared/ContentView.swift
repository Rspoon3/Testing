//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import UIImageColors
import SwiftUI

struct ContentView: View {
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            MovingNumbersBackground()
            
            ZStack {
                if showSettings {
                    SettingsView()
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        ))
                } else {
                    SwipeView()
                }
            }
            .animation(
                .linear(duration: 0.3),
                value: showSettings
            )
        }
        .overlay(alignment: .topLeading) {
            SettingsButton(showSettings: $showSettings)
        }
    }
}

#Preview {
    ContentView()
}
