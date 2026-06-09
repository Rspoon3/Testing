//
//  TestHelpers.swift
//  TestDriveTests
//
//  Created by Ricky Witherspoon on 6/9/26.
//

import Foundation
@testable import TestDrive

extension UserDefaults {
    /// An isolated, empty `UserDefaults` for a single test.
    static func makeEphemeral() -> UserDefaults {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

/// Resolves every pending referral in the store against the backend.
///
/// Mirrors `HomeViewModel.timerDidFinish`: each unresolved code is sent to the
/// backend and its ledger entry is stamped with the eligibility result.
/// - Parameters:
///   - store: The store whose unresolved entries should be resolved.
///   - backend: The backend used to determine eligibility.
/// - Returns: `true` if any resolved code was invalid.
@MainActor
@discardableResult
func resolvePendingReferrals(in store: ReferralCodeStore, using backend: ReferralBackend) -> Bool {
    var sawInvalid = false

    for entry in store.unresolved {
        let isEligible = backend.checkEligibility(userID: entry.userID, referralCode: entry.code)
        let eligability: Eligability = isEligible ? .valid : .invalid
        store.resolve(id: entry.id, eligability: eligability)

        if eligability == .invalid {
            sawInvalid = true
        }
    }

    return sawInvalid
}
