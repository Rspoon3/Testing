//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Image(systemName: "heart")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 100)
            .foregroundStyle(.red)
            .shining(duration: 3, delay: 1)
    }
}

#Preview {
    ContentView()
}
