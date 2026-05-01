//
//  AppRatingAnalyticsEvent.swift
//  AppRatingFeature
//
//  Created on 9/25/25.
//

import Foundation

/// Analytics events for app rating interactions
public enum AppRatingAnalyticsEvent {
    /// Ask-to-ask view was shown
    case askToAskViewed

    /// User selected star rating
    case starsSelected(count: Int)

    /// User dismissed without rating
    case dismissed

    /// Native app store prompt was shown
    case nativePromptShown

    /// User was not eligible (with reason)
    case notEligible(reason: IneligibilityReason)

    public enum IneligibilityReason: String {
        case userTooNew = "user_too_new"
        case notEnoughLaunches = "not_enough_launches"
        case notEnoughPhotoComparisons = "not_enough_photo_comparisons"
        case cooldownActive = "cooldown_active"
        case yearlyLimitReached = "yearly_limit_reached"
        case alreadyRatedVersion = "already_rated_version"
    }
}
