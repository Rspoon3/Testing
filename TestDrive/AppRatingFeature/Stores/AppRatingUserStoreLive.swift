//
//  AppRatingUserStoreLive.swift
//  HotTakesCore
//
//  Created by Ricky Witherspoon on 9/25/25.
//

import Foundation

/// UserDefaults-based implementation of AppRatingUserStore
public final class AppRatingUserStoreLive: AppRatingUserStore {
    public static let shared = AppRatingUserStoreLive()
    
    private let userDefaults: UserDefaults

    private enum Keys {
        static let numberOfLaunches = "numberOfLaunches"
        static let numberOfActivations = "numberOfActivations"
        static let launchDates = "launchDates"
        static let activationDates = "activationDates"
        static let debugOverride = "appRating.debugOverride"
        static let numberOfCompletedPhotoComparisons = "numberOfCompletedPhotoComparisons"
        static let numberOfStartedPhotoComparisons = "numberOfStartedPhotoComparisons"
    }

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public var numberOfCompletedPhotoComparisons: Int {
        userDefaults.integer(forKey: Keys.numberOfCompletedPhotoComparisons)
    }

    public var numberOfStartedPhotoComparisons: Int {
        userDefaults.integer(forKey: Keys.numberOfStartedPhotoComparisons)
    }

    public var numberOfLaunches: Int {
        userDefaults.integer(forKey: Keys.numberOfLaunches)
    }

    public var numberOfActivations: Int {
        userDefaults.integer(forKey: Keys.numberOfActivations)
    }

    public var launchDates: [Date] {
        (userDefaults.array(forKey: Keys.launchDates) as? [Date]) ?? []
    }

    public var activationDates: [Date] {
        (userDefaults.array(forKey: Keys.activationDates) as? [Date]) ?? []
    }

    public var firstLaunchDate: Date? {
        launchDates.first
    }

    public var debugOverrideEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.debugOverride) }
        set { userDefaults.set(newValue, forKey: Keys.debugOverride) }
    }

    public func recordAppLaunch() {
        let newCount = numberOfLaunches + 1
        userDefaults.set(newCount, forKey: Keys.numberOfLaunches)

        var dates = launchDates
        dates.append(.now)
        userDefaults.set(dates, forKey: Keys.launchDates)
    }

    public func recordAppActivation() {
        let newCount = numberOfActivations + 1
        userDefaults.set(newCount, forKey: Keys.numberOfActivations)

        var dates = activationDates
        dates.append(.now)
        userDefaults.set(dates, forKey: Keys.activationDates)
    }
    
    public func recordStartedPhotoComparison() {
        let newCount = numberOfStartedPhotoComparisons + 1
        userDefaults.set(newCount, forKey: Keys.numberOfStartedPhotoComparisons)
    }
    
    public func recordCompletedPhotoComparison() {
        let newCount = numberOfCompletedPhotoComparisons + 1
        userDefaults.set(newCount, forKey: Keys.numberOfCompletedPhotoComparisons)
    }
}
