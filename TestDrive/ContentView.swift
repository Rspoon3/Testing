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

            ScrollView {
                YumiMapView()
            }
            .frame(height: 300)

            Text("Stuff There")
        }
        .background(Color(red: 0.83, green: 0.93, blue: 0.99))
    }
}

#Preview {
    ContentView()
}
