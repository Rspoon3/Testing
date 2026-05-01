//
//  AppTabNavigation.swift
//  Testing (iOS)
//
//  Created by Ricky Witherspoon on 4/14/25.
//

import SwiftUI

public enum Tab {
    case home, stats, settings
}

public final class TabManager: ObservableObject {
    @Published public var selectedTab: Tab = .home
    
    public init() {}
}

struct AppTabNavigation: View {
    @EnvironmentObject var tabManager: TabManager

    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
                    .accessibility(label: Text("Home"))
            }
            .tag(Tab.home)
            
            NavigationStack {
                StatsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle("Stats")
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
                    .accessibility(label: Text("Stats"))
            }
            .tag(Tab.stats)
            
            NavigationStack {
                SettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
                    .accessibility(label: Text("Settings"))
            }
            .tag(Tab.settings)
        }
    }
}

#Preview {
    AppTabNavigation()
        .environmentObject(TabManager())
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
    }
}

struct StatsView: View {
    var body: some View {
        Text("StatsView")
    }
}
