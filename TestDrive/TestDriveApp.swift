//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestDriveApp: App {
    @StateObject private var deepLinkQueue = DeepLinkQueue.shared
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @StateObject private var counterModel = CounterModel.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deepLinkQueue)
                .environmentObject(deepLinkManager)
                .environmentObject(navigationCoordinator)
                .environmentObject(counterModel)
                .onOpenURL { url in
                    print("📱 App received deep link: \(url)")
                    deepLinkQueue.enqueue(url: url)
                }
        }
    }
}
