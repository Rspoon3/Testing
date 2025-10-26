//
//  AppDelegate.swift
//  TestDrive
//
//  Created by Claude on 10/26/25.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Task {
            await StepCountObserver().startObserving()
        }

        return true
    }
}
