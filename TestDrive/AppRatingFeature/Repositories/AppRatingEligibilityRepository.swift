//
//  AppRatingEligibilityRepository.swift
//  AppRatingFeature
//
//  Created on 9/25/25.
//

import Foundation

/// Protocol for checking app rating eligibility
public protocol AppRatingEligibilityRepository {
    /// Whether the user is currently eligible to see the rating prompt
    var isEligible: Bool { get }

    /// Detailed eligibility status for debugging
    var eligibilityStatus: AppRatingEligibilityStatus { get }

    /// Records that the rating prompt was viewed
    func recordPromptViewed()

    /// Records that the user rated the app
    func recordAppRated()
}

