//
//  AppDelegate.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/4/25.
//

import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AppRatingUserStoreLive.shared.recordAppLaunch()
        return true
    }
}
