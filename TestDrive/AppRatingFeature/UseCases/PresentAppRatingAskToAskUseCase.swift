//
//  PresentAppRatingAskToAskUseCase.swift
//  AppRatingFeature
//
//  Created on 9/25/25.
//

import SwiftUI
import StoreKit

/// Protocol for presenting the app rating ask-to-ask flow
public protocol PresentAppRatingAskToAskUseCase {
    /// Checks if eligible and returns whether to show the ask-to-ask view
    @MainActor
    func shouldPresentAskToAsk() -> Bool

    /// Forces presentation regardless of eligibility (for debug)
    @MainActor
    func forceShouldPresent() -> Bool

    /// Records that the prompt was viewed
    @MainActor
    func recordPromptViewed()

    /// Handles rating selection
    @MainActor
    func handleRatingSelection(_ rating: Int)
}
