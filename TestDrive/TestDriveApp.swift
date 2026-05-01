//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import SharingGRDB

@main
struct TestDriveApp: App {
    init() {
        prepareDependencies {
            if let database = DatabaseManager.shared.database {
                $0.defaultDatabase = database
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
