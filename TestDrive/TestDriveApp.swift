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
        let code = appsFlyer.onConversionDataSuccess()
        ReferralCodeStore.shared.record(code: code, source: .conversion)
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            // Deep links are handled in `HomeView` so they can restart the
            // countdown that drives the backend eligibility check.
            HomeView()
        }
    }
}
