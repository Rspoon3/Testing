//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

/// Unused once the app is a `MenuBarExtra`-only target. Kept for SwiftUI previews.
struct ContentView: View {
    var body: some View {
        MenuBarContentView(viewModel: AppViewModel())
    }
}

#Preview {
    ContentView()
}
