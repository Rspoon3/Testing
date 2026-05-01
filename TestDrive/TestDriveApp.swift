//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestDriveApp: App {
    @AppStorage("selectedTab") private var selectedTab: Int = 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                ContentView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Sticky")
                    }
                    .tag(0)

                CornerSnapView()
                    .tabItem {
                        Image(systemName: "star")
                        Text("Snap")
                    }
                    .tag(1)
                
                GooView()
                    .tabItem {
                        Image(systemName: "airplane")
                        Text("Goo")
                    }
                    .tag(2)
            }
        }
    }
}
