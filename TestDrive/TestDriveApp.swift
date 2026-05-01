//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestDriveApp: App {
    private let factory = RootFactory()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.factory, factory)
        }
    }
}
