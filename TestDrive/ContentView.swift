//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

enum Tab {
    case home, settings
}

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @State private var test = false
    
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Text("Home")
                .tabItem {
                    Label("Home", systemImage: "house")
                        .accessibility(label: Text("Home"))
                }
                .tag(Tab.home)
            
            Form {
                Toggle("Automatically save to files", isOn: $test)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
                    .accessibility(label: Text("Settings"))
            }
            .tag(Tab.settings)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
