//
//  AppRatingUserStore.swift
//  AppRatingFeature
//
//  Created on 9/25/25.
//

import Foundation

/// Protocol for storing user-related app rating data
public protocol AppRatingUserStore {
    /// Number of times app has been launched
    var numberOfLaunches: Int { get }

    /// Number of times app has been activated (foreground)
    var numberOfActivations: Int { get }

    /// Dates when the app was launched
    var launchDates: [Date] { get }

    /// Dates when the app was activated (foreground)
    var activationDates: [Date] { get }

    /// First date the app was launched
    var firstLaunchDate: Date? { get }

    /// Whether debug override is enabled
    var debugOverrideEnabled: Bool { get set }

    /// The number of completed photo comparisons
    var numberOfCompletedPhotoComparisons: Int { get }
    
    /// The number of started photo comparisons
    var numberOfStartedPhotoComparisons: Int { get }

    /// Records an app launch
    func recordAppLaunch()

    /// Records an app activation (foreground)
    func recordAppActivation()
    
    func recordStartedPhotoComparison()
    
    func recordCompletedPhotoComparison()
}
