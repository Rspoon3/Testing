//
//  ReferralBackend.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 6/5/26.
//

import Foundation

/// Mimics the referral backend by persisting eligibility to `UserDefaults`.
///
/// The backend enforces that a `userID` can only ever be associated with a
/// single referral code. The first time a user presents a code they are
/// eligible and the code is recorded; every later check returns ineligible.
struct ReferralBackend {
    private let defaults: UserDefaults

    // MARK: - Initializer

    /// Creates a new `ReferralBackend`.
    /// - Parameter defaults: The store backing the mocked backend. Defaults to `.standard`.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Public Helpers

    /// Checks whether a user is eligible to redeem a referral code.
    ///
    /// Mirrors a backend call: if the user has no associated referral code yet
    /// they are eligible and the code is stored, otherwise they are not.
    /// - Parameters:
    ///   - userID: The identifier for the current user.
    ///   - referralCode: The referral code presented by the user.
    /// - Returns: `true` if eligible (and now associated), otherwise `false`.
    func checkEligibility(userID: String, referralCode: String) -> Bool {
        let key = Self.key(for: userID)

        // A userID can only ever have one associated referral code.
        guard defaults.string(forKey: key) == nil else {
            return false
        }

        defaults.set(referralCode, forKey: key)
        return true
    }

    /// The referral code currently associated with a user, if any.
    /// - Parameter userID: The identifier for the user.
    /// - Returns: The associated referral code, or `nil` if none exists.
    func referralCode(for userID: String) -> String? {
        defaults.string(forKey: Self.key(for: userID))
    }

    // MARK: - Private Helpers

    /// The `UserDefaults` key that stores a user's associated referral code.
    private static func key(for userID: String) -> String {
        "referralCode_\(userID)"
    }
}
