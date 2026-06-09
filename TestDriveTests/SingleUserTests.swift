//
//  SingleUserTests.swift
//  TestDriveTests
//
//  Created by Ricky Witherspoon on 6/5/26.
//

import Testing
import Foundation
@testable import TestDrive

@Suite("Single User Tests")
struct SingleUserTests {

    // MARK: - Backend Eligibility

    @Suite("Backend")
    struct Backend {
        private let userID = "user-123"
        private let referralCode = "RICKY1"

        @Test("A user's first referral code is eligible")
        func firstCodeIsEligible() {
            let backend = ReferralBackend(defaults: .makeEphemeral())

            #expect(backend.checkEligibility(userID: userID, referralCode: referralCode))
        }

        @Test("Re-using the same referral code is ineligible")
        func reusedCodeIsIneligible() {
            let backend = ReferralBackend(defaults: .makeEphemeral())

            _ = backend.checkEligibility(userID: userID, referralCode: referralCode)

            #expect(!backend.checkEligibility(userID: userID, referralCode: referralCode))
        }

        @Test("A user can only ever have one associated referral code")
        func onlyOneCodePerUser() {
            let backend = ReferralBackend(defaults: .makeEphemeral())

            _ = backend.checkEligibility(userID: userID, referralCode: referralCode)

            #expect(!backend.checkEligibility(userID: userID, referralCode: "OTHER1"))
            #expect(backend.referralCode(for: userID) == referralCode)
        }

        @Test("A user with no redemption has no associated code")
        func noCodeForUnknownUser() {
            let backend = ReferralBackend(defaults: .makeEphemeral())

            #expect(backend.referralCode(for: userID) == nil)
        }
    }

    // MARK: - Ledger

    @MainActor
    @Suite("Ledger")
    struct Ledger {
        private let referralCode = "RICKY1"

        @Test("A conversion records a single unresolved entry")
        func conversionRecordsUnresolvedEntry() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())

            store.record(code: referralCode, source: .conversion)

            #expect(store.ledger.count == 1)
            let entry = store.ledger.first
            #expect(entry?.code == referralCode)
            #expect(entry?.source == .conversion)
            #expect(entry?.userID == "user-123")
            #expect(entry?.status == .unresolved)
        }

        @Test("A recorded entry captures its receipt date")
        func entryCapturesReceiptDate() throws {
            let store = ReferralCodeStore(defaults: .makeEphemeral())

            store.record(code: referralCode, source: .conversion)

            let entry = try #require(store.ledger.first)
            #expect(abs(entry.date.timeIntervalSinceNow) < 5)
        }

        @Test("A conversion is recorded only once even though it fires every launch")
        func conversionRecordedOnce() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())

            store.record(code: referralCode, source: .conversion)
            store.record(code: referralCode, source: .conversion)
            store.record(code: referralCode, source: .conversion)

            #expect(store.ledger.count == 1)
        }

        @Test("Both deep link callbacks for one open record a single entry")
        func deeplinkCallbacksCollapseToOneEntry() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())

            // onAppOpenAttribution + onDeeplink fire for the same open.
            store.record(code: referralCode, source: .deeplink)
            store.record(code: referralCode, source: .deeplink)

            #expect(store.ledger.count == 1)
        }

        @Test("Resolving an entry updates its status and clears it from unresolved")
        func resolveUpdatesStatus() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())
            store.record(code: referralCode, source: .conversion)
            let id = try! #require(store.ledger.first?.id)

            store.resolve(id: id, eligability: .valid)

            #expect(store.ledger.first?.status == .resolved(.valid))
            #expect(store.unresolved.isEmpty)
        }

        @Test("A re-used code is recorded again as a fresh attempt after resolution")
        func reusedCodeRecordedAgainAfterResolution() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())
            store.record(code: referralCode, source: .deeplink)
            store.resolve(id: store.ledger[0].id, eligability: .valid)

            store.record(code: referralCode, source: .deeplink)

            #expect(store.ledger.count == 2)
            #expect(store.unresolved.count == 1)
        }

        @Test("The ledger is persisted and reloaded from disk")
        func ledgerIsPersisted() {
            let defaults = UserDefaults.makeEphemeral()
            let store = ReferralCodeStore(defaults: defaults)
            store.record(code: referralCode, source: .conversion)

            let reloaded = ReferralCodeStore(defaults: defaults)

            #expect(reloaded.ledger.count == 1)
            #expect(reloaded.ledger.first?.code == referralCode)
        }

        @Test("The selected user identifier is persisted")
        func selectedUserIsPersisted() {
            let defaults = UserDefaults.makeEphemeral()
            let store = ReferralCodeStore(defaults: defaults)

            store.userID = "user-456"

            #expect(ReferralCodeStore(defaults: defaults).userID == "user-456")
        }

        @Test("The default user identifier is the first selectable one")
        func defaultUserIsFirst() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())

            #expect(store.userID == ReferralCodeStore.userIDs.first)
        }
    }

    // MARK: - Integration

    @MainActor
    @Suite("Resolution Flow")
    struct ResolutionFlow {
        private let referralCode = "RICKY1"

        @Test("A first redemption resolves as valid")
        func firstRedemptionResolvesValid() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())
            let backend = ReferralBackend(defaults: .makeEphemeral())

            store.record(code: referralCode, source: .conversion)
            let sawInvalid = resolvePendingReferrals(in: store, using: backend)

            #expect(!sawInvalid)
            #expect(store.ledger.last?.status == .resolved(.valid))
        }

        @Test("Re-using a code via deep link resolves as invalid")
        func reuseResolvesInvalid() {
            let store = ReferralCodeStore(defaults: .makeEphemeral())
            let backend = ReferralBackend(defaults: .makeEphemeral())

            // First, valid redemption.
            store.record(code: referralCode, source: .conversion)
            resolvePendingReferrals(in: store, using: backend)

            // Then, re-use the same code via a deep link.
            store.record(code: referralCode, source: .deeplink)
            let sawInvalid = resolvePendingReferrals(in: store, using: backend)

            #expect(sawInvalid)
            let deeplinkEntry = store.ledger.first { $0.source == .deeplink }
            #expect(deeplinkEntry?.status == .resolved(.invalid))
        }
    }
}
