//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    @State private var urls: [URL] = []

    var body: some View {
        TabView {
            Tab("UIKit (works)", systemImage: "checkmark.circle") {
                DropCollectionView(droppedURLs: $urls)
            }
            Tab("SwiftUI (broken)", systemImage: "xmark.circle") {
                SwiftUIDropListView()
            }
        }
    }
}

#Preview {
    ContentView()
}
