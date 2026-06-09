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
    private(set) var startDate: Date

    /// Whether the ineligible warning box is currently shown.
    private(set) var showsIneligibleWarning = false

    /// The total length of the countdown, in seconds.
    private let duration: TimeInterval

    /// The store holding the persisted incoming referral code.
    private let store: ReferralCodeStore

    /// The mocked backend used to resolve referral eligibility.
    private let backend: ReferralBackend

    /// Mimics the AppsFlyer SDK for deep link callbacks.
    private let appsFlyer = AppsFlyerManager()

    // MARK: - Initializer

    /// Creates a new `HomeViewModel`.
    /// - Parameters:
    ///   - duration: The countdown length in seconds. Defaults to 3.
    ///   - backend: The mocked referral backend.
    ///   - store: The store holding the incoming referral code. Defaults to the shared store.
    init(
        duration: TimeInterval = 3,
        backend: ReferralBackend = ReferralBackend(),
        store: ReferralCodeStore = .shared
    ) {
        self.startDate = .now
        self.duration = duration
        self.backend = backend
        self.store = store
    }

    // MARK: - Public Helpers

    /// Handles an incoming deep link.
    ///
    /// Records the deep link's referral code and restarts the countdown so the
    /// new code is sent to the backend even if a previous countdown already
    /// finished (e.g. the app was already running).
    func handleDeeplink() {
        store.record(code: appsFlyer.onAppOpenAttribution(), source: .deeplink)
        store.record(code: appsFlyer.onDeeplink(), source: .deeplink)
        startDate = .now
    }

    /// Handles the settings screen being dismissed.
    ///
    /// If a new user has logged in, their referral code has not been resolved
    /// yet, so it is recorded and the countdown is restarted to send it to the
    /// backend for eligibility. For an unchanged user there is nothing to
    /// resolve and the countdown is left alone.
    func settingsDidDismiss() {
        store.record(code: appsFlyer.onConversionDataSuccess(), source: .conversion)

        guard !store.unresolved.isEmpty else { return }

        startDate = .now
    }

    /// The seconds remaining in the countdown at the given date.
    /// - Parameter date: The current timeline date.
    /// - Returns: The seconds left to thousandth precision, clamped at zero.
    func remainingSeconds(at date: Date) -> TimeInterval {
        let elapsed = date.timeIntervalSince(startDate)
        return max(0, duration - elapsed)
    }

    /// Called when the countdown reaches zero.
    ///
    /// Forwards every unresolved referral code to the backend and records its
    /// eligibility in the store. If any code is invalid, a red warning box is
    /// shown for two seconds.
    func timerDidFinish() {
        var sawInvalid = false

        for entry in store.unresolved {
            let isEligible = backend.checkEligibility(
                userID: entry.userID,
                referralCode: entry.code
            )
            let eligability: Eligability = isEligible ? .valid : .invalid
            store.resolve(id: entry.id, eligability: eligability)

            if eligability == .invalid {
                sawInvalid = true
            }
        }

        guard sawInvalid else { return }

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
