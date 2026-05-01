//
//  AppRatingEligibilityRequirement.swift
//  AppRatingFeature
//
//  Created on 9/25/25.
//

import Foundation

/// Defines the requirements for app rating eligibility
public struct AppRatingEligibilityRequirement {
    /// Number of times the rating prompt can be shown per year
    public let maxTimesShownPerYear: Int

    /// Minimum days between rating prompts
    public let coolDownDays: Int

    /// Minimum days user account must exist before showing prompt
    public let minDaysUserExisted: Int

    /// Minimum number of app launches before showing prompt
    public let minLaunches: Int

    /// Minimum number of games played before showing prompt
    public let minPhotoComparisons: Int

    /// Whether debug override is enabled
    public let debugOverrideEnabled: Bool

    public init(
        maxTimesShownPerYear: Int = 3,
        coolDownDays: Int = 30,
        minDaysUserExisted: Int = 1,
        minLaunches: Int = 3,
        minPhotoComparisons: Int = 3,
        debugOverrideEnabled: Bool = false
    ) {
        self.maxTimesShownPerYear = maxTimesShownPerYear
        self.coolDownDays = coolDownDays
        self.minDaysUserExisted = minDaysUserExisted
        self.minLaunches = minLaunches
        self.minPhotoComparisons = minPhotoComparisons
        self.debugOverrideEnabled = debugOverrideEnabled
    }

    /// Default requirements based on best practices
    public static let `default` = AppRatingEligibilityRequirement()
}
