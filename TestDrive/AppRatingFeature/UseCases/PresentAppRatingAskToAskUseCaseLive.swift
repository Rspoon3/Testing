//
//  PresentAppRatingAskToAskUseCaseLive.swift
//  HotTakesCore
//
//  Created by Ricky Witherspoon on 9/25/25.
//

import UIKit
import StoreKit

/// Live implementation of the app rating ask-to-ask use case
public final class PresentAppRatingAskToAskUseCaseLive: PresentAppRatingAskToAskUseCase {
    private let eligibilityRepository: AppRatingEligibilityRepository
    private let analytics: AppRatingAnalyticsRecording
    private let userStore: AppRatingUserStore

    public init(
        eligibilityRepository: AppRatingEligibilityRepository,
        analytics: AppRatingAnalyticsRecording = ConsoleAppRatingAnalyticsRecorder(),
        userStore: AppRatingUserStore
    ) {
        self.eligibilityRepository = eligibilityRepository
        self.analytics = analytics
        self.userStore = userStore
    }

    @MainActor
    public func shouldPresentAskToAsk() -> Bool {
        // Check eligibility
        guard eligibilityRepository.isEligible else {
            let status = eligibilityRepository.eligibilityStatus
            for reason in status.ineligibilityReasons {
                analytics.recordEvent(.notEligible(reason: reason))
            }
            return false
        }

        return true
    }

    @MainActor
    public func forceShouldPresent() -> Bool {
        return true
    }

    @MainActor
    public func recordPromptViewed() {
        eligibilityRepository.recordPromptViewed()
    }

    @MainActor
    public func handleRatingSelection(_ rating: Int) {
        // If 4+ stars, show native prompt
        if rating >= 4 {
            // Record that we're showing native prompt
            analytics.recordEvent(.nativePromptShown)
            eligibilityRepository.recordAppRated()

            // Request native review
            Task {
                // Small delay for better UX
                try? await Task.sleep(for: .seconds(0.5))

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    AppStore.requestReview(in: windowScene)
                }
            }
        } else {
            // User gave low rating, just record it
            analytics.recordEvent(.dismissed)
        }
    }
}
