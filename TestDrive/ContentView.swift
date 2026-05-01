//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RadialBurstView(
            colors: [
                Color.clear,
                Color.red.opacity(0.2),
            ],
            rayCount: 62,
            opacity: 1,
            animationDuration: 300
        )
        .clipShape(Circle())
    }
}

#Preview {
    ContentView()
}
