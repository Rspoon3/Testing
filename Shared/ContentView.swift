//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

public enum Tab {
    case main
}

struct AppTabNavigation: View {
    @State private var tabSelection = Tab.main
    
    var body: some View {
        TabView(selection: $tabSelection) {
            NavigationStack { // Changed to NavigationView to work
                ContentView()
            }
            .tag(Tab.main)
            .tabItem {
                Label("Main", systemImage: "star")
            }
        }
    }
}

struct ContentView: View {
    @State private var searchText = ""
    
    var body: some View {
        List(0..<100) { i in
            NavigationLink {
                DetailsView(i: i)
            } label: {
                Text("Select \(i)")
            }
        }
        .navigationTitle("Main")
        .searchable(text: $searchText)
    }
}

struct DetailsView: View {
    @State private var searchText = ""
    let i: Int
    
    // MARK: - Body
    
    var body: some View {
        List {
            ForEach(0..<10, id: \.self) { i in
                Text("Hello \(i)")
            }
        }
        .navigationTitle(i.formatted())
        .searchable(text: $searchText)
    }
}
