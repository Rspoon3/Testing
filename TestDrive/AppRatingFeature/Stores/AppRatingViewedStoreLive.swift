//
//  AppRatingViewedStoreLive.swift
//  HotTakesCore
//
//  Created by Ricky Witherspoon on 9/25/25.
//

import Foundation

/// UserDefaults-based implementation of AppRatingViewedStore
public final class AppRatingViewedStoreLive: AppRatingViewedStore {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let viewedHistory = "appRating.viewedHistory"
        static let lastRatedVersion = "appRating.lastRatedVersion"
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public var viewedHistory: [Date] {
        userDefaults.object(forKey: Keys.viewedHistory) as? [Date] ?? []
    }

    public var lastRatedVersion: String? {
        userDefaults.string(forKey: Keys.lastRatedVersion)
    }

    public func updateViewedHistory(adding date: Date) {
        let existingHistory = viewedHistory
        let newHistory = existingHistory + [date]
        userDefaults.set(newHistory, forKey: Keys.viewedHistory)
    }

    public func setLastRatedVersion(_ version: String) {
        userDefaults.set(version, forKey: Keys.lastRatedVersion)
    }

    public func clearAll() {
        userDefaults.removeObject(forKey: Keys.viewedHistory)
        userDefaults.removeObject(forKey: Keys.lastRatedVersion)
    }
}
