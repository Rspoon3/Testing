//
//  MockPresentAppRatingAskToAskUseCase.swift
//  HotTakesCore
//
//  Created by Ricky Witherspoon on 9/25/25.
//

import Foundation

/// Mock implementation for testing/preview
public final class MockPresentAppRatingAskToAskUseCase: PresentAppRatingAskToAskUseCase {
    public var shouldPresentCalled = false
    public var forceShouldPresentCalled = false
    public var recordPromptViewedCalled = false
    public var handleRatingSelectionCalled = false
    public var lastRating: Int?

    public init() {}

    @MainActor
    public func shouldPresentAskToAsk() -> Bool {
        shouldPresentCalled = true
        return true
    }

    @MainActor
    public func forceShouldPresent() -> Bool {
        forceShouldPresentCalled = true
        return true
    }

    @MainActor
    public func recordPromptViewed() {
        recordPromptViewedCalled = true
    }

    @MainActor
    public func handleRatingSelection(_ rating: Int) {
        handleRatingSelectionCalled = true
        lastRating = rating
    }
}
