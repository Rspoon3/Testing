//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Intended API", systemImage: "exclamationmark.triangle") {
                IntendedDropConfigurationDemoView()
            }
            Tab("Workaround Lab", systemImage: "checkmark.seal") {
                DragDropLabView()
            }
        }
    }
}

#Preview {
    ContentView()
}
