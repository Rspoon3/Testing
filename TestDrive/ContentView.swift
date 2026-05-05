//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            Text("Stuff Here")
                .font(.largeTitle)

            ScrollView {
                YumiMapView()
            }
            .frame(height: 300)

            ContentUnavailableView(
                "More to come",
                systemImage: "text.bubble"
            )
            .padding()
            .border(Color.red, width: 1)
            .padding()
        }
        .background(Color.blue.opacity(0.05))
    }
}

#Preview {
    ContentView()
}
