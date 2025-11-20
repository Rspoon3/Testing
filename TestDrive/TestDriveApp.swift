//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI
import SQLiteData

@main
struct TestDriveApp: App {
    // MARK: - Initializer

    init() {
        prepareDependencies {
            do {
                $0.defaultDatabase = try DatabaseManager.createHighlightsDatabase()
            } catch {
                fatalError("Failed to initialize highlights database: \(error)")
            }
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            TranscriptDemoView()
        }
    }
}
