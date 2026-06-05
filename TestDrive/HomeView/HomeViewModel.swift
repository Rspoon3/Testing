//
//  HomeViewModel.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 6/5/26.
//

import Foundation

/// Drives the home screen's countdown that runs when the view appears.
@MainActor
@Observable
final class HomeViewModel {
    /// The moment the countdown began, used as the `TimelineView` anchor.
    let startDate: Date

    /// Whether the ineligible warning box is currently shown.
    private(set) var showsIneligibleWarning = false

    /// The total length of the countdown, in seconds.
    private let duration: TimeInterval

    /// The current user's identifier.
    private let userID: String

    /// The referral code presented by the user (provided by AppsFlyer).
    private let referralCode: String

    /// The mocked backend used to resolve referral eligibility.
    private let backend: ReferralBackend

    // MARK: - Initializer

    /// Creates a new `HomeViewModel`.
    /// - Parameters:
    ///   - duration: The countdown length in seconds. Defaults to 3.
    ///   - userID: The current user's identifier.
    ///   - referralCode: The referral code presented by the user.
    ///   - backend: The mocked referral backend.
    init(
        duration: TimeInterval = 3,
        userID: String = "user-123",
        referralCode: String = "RICKY1",
        backend: ReferralBackend = ReferralBackend()
    ) {
        self.startDate = .now
        self.duration = duration
        self.userID = userID
        self.referralCode = referralCode
        self.backend = backend
    }

    // MARK: - Public Helpers

    /// The seconds remaining in the countdown at the given date.
    /// - Parameter date: The current timeline date.
    /// - Returns: The seconds left to thousandth precision, clamped at zero.
    func remainingSeconds(at date: Date) -> TimeInterval {
        let elapsed = date.timeIntervalSince(startDate)
        return max(0, duration - elapsed)
    }

    /// Called when the countdown reaches zero.
    ///
    /// Mimics the backend eligibility call. If the user is not eligible, a red
    /// warning box is shown for two seconds.
    func timerDidFinish() {
        let isEligible = backend.checkEligibility(
            userID: userID,
            referralCode: referralCode
        )

        guard !isEligible else { return }

        showIneligibleWarning()
    }

    // MARK: - Private Helpers

    /// Shows the ineligible warning box for two seconds, then hides it.
    private func showIneligibleWarning() {
        showsIneligibleWarning = true

        Task {
            try? await Task.sleep(for: .seconds(2))
            showsIneligibleWarning = false
        }
    }
}
