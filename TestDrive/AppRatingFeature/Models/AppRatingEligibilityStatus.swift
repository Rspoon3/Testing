//
//  AppRatingEligibilityStatus.swift
//  HotTakesCore
//
//  Created by Ricky Witherspoon on 9/25/25.
//

import Foundation

/// Detailed eligibility status
public struct AppRatingEligibilityStatus {
    public let isEligible: Bool
    public let numberOfLaunches: Int
    public let numberOfActivations: Int
    public let daysSinceLastPrompt: Int?
    public let timesShownThisYear: Int
    public let hasRatedCurrentVersion: Bool
    public let debugOverrideEnabled: Bool
    public let ineligibilityReasons: Set<AppRatingAnalyticsEvent.IneligibilityReason>

    public init(
        isEligible: Bool,
        numberOfLaunches: Int,
        numberOfActivations: Int,
        daysSinceLastPrompt: Int?,
        timesShownThisYear: Int,
        hasRatedCurrentVersion: Bool,
        debugOverrideEnabled: Bool,
        ineligibilityReasons: Set<AppRatingAnalyticsEvent.IneligibilityReason>
    ) {
        self.isEligible = isEligible
        self.numberOfLaunches = numberOfLaunches
        self.numberOfActivations = numberOfActivations
        self.daysSinceLastPrompt = daysSinceLastPrompt
        self.timesShownThisYear = timesShownThisYear
        self.hasRatedCurrentVersion = hasRatedCurrentVersion
        self.debugOverrideEnabled = debugOverrideEnabled
        self.ineligibilityReasons = ineligibilityReasons
    }
}
