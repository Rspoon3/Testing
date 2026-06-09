//
//  HomeViewModelTests.swift
//  TestDriveTests
//
//  Created by Ricky Witherspoon on 6/9/26.
//

import Testing
import Foundation
@testable import TestDrive

@MainActor
@Suite("Home View Model Tests")
struct HomeViewModelTests {
    private let referralCode = "RICKY1"

    // MARK: - Countdown

    @Test("The countdown starts at the full duration")
    func countdownStartsFull() {
        let viewModel = makeViewModel(duration: 3)

        #expect(viewModel.remainingSeconds(at: viewModel.startDate) == 3)
    }

    @Test("The countdown decreases as time elapses")
    func countdownDecreases() {
        let viewModel = makeViewModel(duration: 3)
        let oneSecondLater = viewModel.startDate.addingTimeInterval(1)

        #expect(viewModel.remainingSeconds(at: oneSecondLater) == 2)
    }

    @Test("The countdown is clamped at zero")
    func countdownClampedAtZero() {
        let viewModel = makeViewModel(duration: 3)
        let wellPastEnd = viewModel.startDate.addingTimeInterval(10)

        #expect(viewModel.remainingSeconds(at: wellPastEnd) == 0)
    }

    // MARK: - Eligibility Warning

    @Test("An eligible code does not show the warning")
    func eligibleHidesWarning() {
        let store = ReferralCodeStore(defaults: .makeEphemeral())
        let viewModel = makeViewModel(store: store)

        store.record(code: referralCode, source: .conversion)
        viewModel.timerDidFinish()

        #expect(!viewModel.showsIneligibleWarning)
    }

    @Test("An ineligible code shows the warning")
    func ineligibleShowsWarning() {
        let store = ReferralCodeStore(defaults: .makeEphemeral())
        let viewModel = makeViewModel(store: store)

        // First redemption consumes the user's eligibility.
        store.record(code: referralCode, source: .conversion)
        viewModel.timerDidFinish()

        // Re-using the code is now ineligible.
        store.record(code: referralCode, source: .deeplink)
        viewModel.timerDidFinish()

        #expect(viewModel.showsIneligibleWarning)
    }

    // MARK: - Deep Links

    @Test("Handling a deep link records a deep link attempt")
    func handleDeeplinkRecordsAttempt() {
        let store = ReferralCodeStore(defaults: .makeEphemeral())
        let viewModel = makeViewModel(store: store)

        viewModel.handleDeeplink()

        #expect(store.unresolved.contains { $0.source == .deeplink })
    }

    // MARK: - Settings Dismissal (multi-user login)

    @Test("Dismissing settings for a newly logged-in user records their referral")
    func settingsDismissRecordsForNewUser() {
        let store = ReferralCodeStore(defaults: .makeEphemeral())
        let viewModel = makeViewModel(store: store)
        seedResolvedConversion(in: store, for: "user-123")

        store.userID = "user-456"
        viewModel.settingsDidDismiss()

        #expect(store.unresolved.contains { $0.userID == "user-456" && $0.source == .conversion })
    }

    @Test("Dismissing settings for an unchanged user records nothing new")
    func settingsDismissNoOpForSameUser() {
        let store = ReferralCodeStore(defaults: .makeEphemeral())
        let viewModel = makeViewModel(store: store)
        seedResolvedConversion(in: store, for: "user-123")
        let countBefore = store.ledger.count

        viewModel.settingsDidDismiss()

        #expect(store.ledger.count == countBefore)
        #expect(store.unresolved.isEmpty)
    }

    // MARK: - Helpers

    private func makeViewModel(
        duration: TimeInterval = 3,
        store: ReferralCodeStore? = nil
    ) -> HomeViewModel {
        HomeViewModel(
            duration: duration,
            backend: ReferralBackend(defaults: .makeEphemeral()),
            store: store ?? ReferralCodeStore(defaults: .makeEphemeral())
        )
    }

    private func seedResolvedConversion(in store: ReferralCodeStore, for userID: String) {
        store.userID = userID
        store.record(code: referralCode, source: .conversion)
        store.resolve(id: store.ledger[0].id, eligability: .valid)
    }
}
