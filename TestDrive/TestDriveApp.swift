//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

@main
struct TestDriveApp: App {
    private let appsFlyer = AppsFlyerManager()

    // MARK: - Initializer

    init() {
        // `onConversionDataSuccess` fires on every app load.
        appsFlyer.onConversionDataSuccess()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            HomeView()
                .onOpenURL { _ in
                    // Deep link listeners fire only when opened via a deep link.
                    appsFlyer.onAppOpenAttribution()
                    appsFlyer.onDeeplink()
                }
        }
    }
}
