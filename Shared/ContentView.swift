//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack {
            VStack {
                Text("This is a test")
                    .font(.largeTitle)
                    .shimmeringV2()
                
                Image(systemName: "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .foregroundStyle(.red)
                    .shimmeringV2()
                
                Text("This is a test")
                    .font(.largeTitle)
                    .shiningV2(duration: 3, delay: 1)

                Image(systemName: "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .foregroundStyle(.red)
                    .shiningV2(duration: 3, delay: 1)
            }
            VStack {
                Text("This is a test")
                    .font(.largeTitle)
                    .shimmeringLegacy()
                
                Image(systemName: "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .foregroundStyle(.red)
                    .shimmeringLegacy()
                
                Text("This is a test")
                    .font(.largeTitle)
                    .shiningLegacy(duration: 3, delay: 1)

                Image(systemName: "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .foregroundStyle(.red)
                    .shiningLegacy(duration: 3, delay: 1)
            }
        }
    }
}

#Preview {
    ContentView()
}
