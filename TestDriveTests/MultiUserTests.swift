//
//  MultiUserTests.swift
//  TestDriveTests
//
//  Created by Ricky Witherspoon on 6/9/26.
//

import Testing
import Foundation
@testable import TestDrive

private let userA = "user-123"
private let userB = "user-456"
private let referralCode = "RICKY1"

@Suite("Multi User Tests")
struct MultiUserTests {

    // MARK: - Backend Eligibility

    @Suite("Backend")
    struct Backend {
        @Test("Each user is evaluated independently")
        func eachUserEvaluatedIndependently() {
            let backend = ReferralBackend(defaults: .makeEphemeral())

            #expect(backend.checkEligibility(userID: userA, referralCode: referralCode))
            #expect(backend.checkEligibility(userID: userB, referralCode: referralCode))
        }

        @Test("One user's reuse does not affect another user")
        func reuseIsolatedPerUser() {
            let backend = ReferralBackend(defaults: .makeEphemeral())

            _ = backend.checkEligibility(userID: userA, referralCode: referralCode)

            // userA re-using is invalid, but userB's first attempt is still valid.
            #expect(!backend.checkEligibility(userID: userA, referralCode: referralCode))
            #expect(backend.checkEligibility(userID: userB, referralCode: referralCode))
        }

        @Test("Each user keeps their own associated referral code")
        func eachUserKeepsOwnCode() {
            let backend = ReferralBackend(defaults: .makeEphemeral())

            _ = backend.checkEligibility(userID: userA, referralCode: referralCode)
            _ = backend.checkEligibility(userID: userB, referralCode: "OTHER1")

            #expect(backend.referralCode(for: userA) == referralCode)
            #expect(backend.referralCode(for: userB) == "OTHER1")
        }
    }

    // MARK: - Ledger

    @MainActor
    @Suite("Ledger")
    struct Ledger {
        @Test("A newly logged-in user gets their own conversion entry")
        func newUserGetsOwnConversion() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())

            store.userID = userA
            store.record(code: referralCode, source: .conversion)

            store.userID = userB
            store.record(code: referralCode, source: .conversion)

            let conversions = store.ledger.filter { $0.source == .conversion }
            #expect(conversions.count == 2)
            #expect(store.ledger.contains { $0.userID == userA })
            #expect(store.ledger.contains { $0.userID == userB })
        }

        @Test("Conversion dedup is scoped per user")
        func conversionDedupPerUser() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())

            store.userID = userA
            store.record(code: referralCode, source: .conversion)
            store.record(code: referralCode, source: .conversion)

            store.userID = userB
            store.record(code: referralCode, source: .conversion)

            // One entry per user, despite the repeated calls.
            #expect(store.ledger.count == 2)
        }

        @Test("Deep link dedup is scoped per user")
        func deeplinkDedupPerUser() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())

            store.userID = userA
            store.record(code: referralCode, source: .deeplink)

            // userB's deep link is recorded even though userA has an unresolved
            // entry for the same code.
            store.userID = userB
            store.record(code: referralCode, source: .deeplink)

            #expect(store.ledger.count == 2)
        }

        @Test("Ledger entries are stamped with the active user at record time")
        func entriesStampedWithActiveUser() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())

            store.userID = userA
            store.record(code: referralCode, source: .conversion)
            store.userID = userB
            store.record(code: referralCode, source: .deeplink)

            #expect(store.ledger.first { $0.source == .conversion }?.userID == userA)
            #expect(store.ledger.first { $0.source == .deeplink }?.userID == userB)
        }
    }

    // MARK: - Integration

    @MainActor
    @Suite("Resolution Flow")
    struct ResolutionFlow {
        @Test("Two users can redeem the same code independently")
        func bothUsersRedeemIndependently() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())
            let backend = ReferralBackend(defaults: .makeEphemeral())

            store.userID = userA
            store.record(code: referralCode, source: .conversion)
            #expect(!resolvePendingReferrals(in: store, using: backend))

            store.userID = userB
            store.record(code: referralCode, source: .conversion)
            #expect(!resolvePendingReferrals(in: store, using: backend))

            #expect(store.ledger.first { $0.userID == userA }?.status == .resolved(.valid))
            #expect(store.ledger.first { $0.userID == userB }?.status == .resolved(.valid))
        }

        @Test("Re-use is invalid for one user while a new user stays valid")
        func reuseInvalidButNewUserValid() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())
            let backend = ReferralBackend(defaults: .makeEphemeral())

            // userA redeems, then re-uses via deep link.
            store.userID = userA
            store.record(code: referralCode, source: .conversion)
            resolvePendingReferrals(in: store, using: backend)
            store.record(code: referralCode, source: .deeplink)
            #expect(resolvePendingReferrals(in: store, using: backend))

            // userB logs in fresh and is still valid.
            store.userID = userB
            store.record(code: referralCode, source: .conversion)
            #expect(!resolvePendingReferrals(in: store, using: backend))

            let userADeeplink = store.ledger.first { $0.userID == userA && $0.source == .deeplink }
            #expect(userADeeplink?.status == .resolved(.invalid))
            #expect(store.ledger.first { $0.userID == userB }?.status == .resolved(.valid))
        }
    }
}
