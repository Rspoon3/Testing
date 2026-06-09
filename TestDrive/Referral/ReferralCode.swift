//
//  ReferralCode.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 6/5/26.
//

import Foundation

/// A referral code received from AppsFlyer, along with how and when it arrived
/// and whether the backend has resolved its eligibility.
struct ReferralCode: Codable, Equatable, Identifiable {
    /// A stable identifier for the ledger entry.
    let id: UUID

    /// The referral code value.
    let code: String

    /// The moment the code was received.
    let date: Date

    /// The AppsFlyer listener that produced the code.
    let source: AnalyticsSource

    /// The identifier of the user the code is associated with.
    let userID: String

    /// Whether the backend has resolved the code's eligibility.
    var status: Status

    // MARK: - Initializer

    /// Creates a new `ReferralCode`.
    /// - Parameters:
    ///   - id: A stable identifier. Defaults to a new `UUID`.
    ///   - code: The referral code value.
    ///   - date: The moment the code was received.
    ///   - source: The AppsFlyer listener that produced the code.
    ///   - userID: The identifier of the associated user.
    ///   - status: The resolution status. Defaults to `.unresolved`.
    init(
        id: UUID = UUID(),
        code: String,
        date: Date,
        source: AnalyticsSource,
        userID: String,
        status: Status = .unresolved
    ) {
        self.id = id
        self.code = code
        self.date = date
        self.source = source
        self.userID = userID
        self.status = status
    }
}
