//
//  TestingApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestingApp: App {
    @State private var tabManager = TabManager()

    var body: some Scene {
        WindowGroup {
            AppTabNavigation()
                .environment(tabManager)
        }
    }
}


public enum Tab {
    case home, settings, three, plates, test
}


@Observable
public final class TabManager {
    public var selectedTab: Tab = .home
    
    public init() {}
}


public struct AppTabNavigation: View {
    @Environment(TabManager.self) private var tabManager

    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        @Bindable var tabManager = tabManager
        
        TabView(selection: $tabManager.selectedTab) {
            NavigationStack {
                FunTripsView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
                    .accessibility(label: Text("Home"))
            }
            .tag(Tab.test)
            
            NavigationStack {
                PlatesView()
            }
            .tabItem {
                Label("Plates", systemImage: "house")
                    .accessibility(label: Text("Home"))
            }
            .tag(Tab.plates)
            
            NavigationStack {
                TripsView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
                    .accessibility(label: Text("Home"))
            }
            .tag(Tab.three)
            
            NavigationStack {
                PlatesView()
            }
            .tabItem {
                Label("Plates", systemImage: "house")
                    .accessibility(label: Text("Home"))
            }
            .tag(Tab.plates)
            
            NavigationStack {
                CoolTripView(
                    trip: .init(
                        name: "ricky",
                        startDate: .now,
                        endDate: .now.addingTimeInterval(80000),
                        description: "This design combines playfulness, interactive elements, and clean aesthetics to make the trip view exciting and enjoyable for users. Let me know how you’d like to adjust or enhance this!",
                        icon: "star",
                        trackedPlates: [.newHampshire]
                    )
                )
            }
            .tabItem {
                Label("Home", systemImage: "house")
                    .accessibility(label: Text("Home"))
            }
            .tag(Tab.home)
            
//            NavigationStack {
                MapView()
//            }
            .tabItem {
                Label("Settings", systemImage: "map")
                    .accessibility(label: Text("Map"))
            }
            .tag(Tab.settings)
        }
    }
}

struct AppTabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        AppTabNavigation()
    }
}
