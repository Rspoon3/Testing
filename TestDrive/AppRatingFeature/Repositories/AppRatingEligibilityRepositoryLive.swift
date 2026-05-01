//
//  AppRatingEligibilityRepositoryLive.swift
//  HotTakesCore
//
//  Created by Ricky Witherspoon on 9/25/25.
//

import Foundation

/// Live implementation of AppRatingEligibilityRepository
public final class AppRatingEligibilityRepositoryLive: AppRatingEligibilityRepository {
    private let viewedStore: AppRatingViewedStore
    private let userStore: AppRatingUserStore
    private let requirements: AppRatingEligibilityRequirement
    private let currentVersion: String
    private let calendar: Calendar

    public init(
        viewedStore: AppRatingViewedStore,
        userStore: AppRatingUserStore,
        requirements: AppRatingEligibilityRequirement = .default,
        currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
        calendar: Calendar = .current
    ) {
        self.viewedStore = viewedStore
        self.userStore = userStore
        self.requirements = requirements
        self.currentVersion = currentVersion
        self.calendar = calendar
    }

    public var isEligible: Bool {
        // Debug override bypasses all checks
        if userStore.debugOverrideEnabled {
            return true
        }

        return eligibilityStatus.isEligible
    }

    public var eligibilityStatus: AppRatingEligibilityStatus {
        var ineligibilityReasons: Set<AppRatingAnalyticsEvent.IneligibilityReason> = []

        // Check minimum launches
        let numberOfLaunches = userStore.numberOfLaunches
        if numberOfLaunches < requirements.minLaunches {
            ineligibilityReasons.insert(.notEnoughLaunches)
        }

        // Check user age
        if let firstLaunchDate = userStore.firstLaunchDate {
            let daysSinceFirstLaunch = calendar.dateComponents([.day], from: firstLaunchDate, to: .now).day ?? 0
            if daysSinceFirstLaunch < requirements.minDaysUserExisted {
                ineligibilityReasons.insert(.userTooNew)
            }
        } else {
            ineligibilityReasons.insert(.userTooNew)
        }

        // Check photo comparisons
        let numberOfCompletedPhotoComparisons = userStore.numberOfCompletedPhotoComparisons
        if numberOfCompletedPhotoComparisons < requirements.minPhotoComparisons {
            ineligibilityReasons.insert(.notEnoughPhotoComparisons)
        }

        // Check if already rated current version
        let hasRatedCurrentVersion = viewedStore.lastRatedVersion == currentVersion
        if hasRatedCurrentVersion {
            ineligibilityReasons.insert(.alreadyRatedVersion)
        }

        // Check cooldown period
        let daysSinceLastPrompt = daysSinceLastPromptShown()
        if let days = daysSinceLastPrompt, days < requirements.coolDownDays {
            ineligibilityReasons.insert(.cooldownActive)
        }

        // Check yearly limit
        let timesShownThisYear = promptsShownThisYear()
        if timesShownThisYear >= requirements.maxTimesShownPerYear {
            ineligibilityReasons.insert(.yearlyLimitReached)
        }

        let isEligible = ineligibilityReasons.isEmpty || userStore.debugOverrideEnabled

        return AppRatingEligibilityStatus(
            isEligible: isEligible,
            numberOfLaunches: numberOfLaunches,
            numberOfActivations: userStore.numberOfActivations,
            daysSinceLastPrompt: daysSinceLastPrompt,
            timesShownThisYear: timesShownThisYear,
            hasRatedCurrentVersion: hasRatedCurrentVersion,
            debugOverrideEnabled: userStore.debugOverrideEnabled,
            ineligibilityReasons: ineligibilityReasons
        )
    }

    public func recordPromptViewed() {
        viewedStore.updateViewedHistory(adding: .now)
    }

    public func recordAppRated() {
        viewedStore.setLastRatedVersion(currentVersion)
    }

    // MARK: - Private Helpers

    private func daysSinceLastPromptShown() -> Int? {
        guard let lastPromptDate = viewedStore.viewedHistory.last else { return nil }
        let days = calendar.dateComponents([.day], from: lastPromptDate, to: .now).day
        return days
    }

    private func promptsShownThisYear() -> Int {
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: .now) ?? .now
        let thisYearPrompts = viewedStore.viewedHistory.filter { date in
            date > oneYearAgo
        }
        return thisYearPrompts.count
    }
}
