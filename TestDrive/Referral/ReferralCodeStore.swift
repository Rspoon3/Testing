//
//  ReferralCodeStore.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 6/5/26.
//

import Foundation

/// Persists the referral code received from AppsFlyer until it can be processed.
///
/// The code arrives at launch but isn't sent to the backend until the home
/// screen countdown finishes. Persisting it here means a code is not lost if
/// the app is quit before the countdown completes; it is reloaded on the next
/// launch and processed then.
@MainActor
final class ReferralCodeStore {
    /// The shared store used throughout the app.
    static let shared = ReferralCodeStore()

    /// The user identifiers that can be selected in Settings.
    static let userIDs = ["user-123", "user-456", "user-789"]

    /// The store backing persistence.
    private let defaults: UserDefaults

    private let ledgerKey = "referral.ledger"
    private let userIDKey = "referral.userID"

    // MARK: - Initializer

    /// Creates a new `ReferralCodeStore`.
    ///
    /// App code uses ``shared``; a custom `defaults` is provided for tests so
    /// they can run against an isolated store.
    /// - Parameter defaults: The store backing persistence. Defaults to `.standard`.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Public Helpers

    /// The identifier of the current user, selectable in Settings and persisted.
    var userID: String {
        get { defaults.string(forKey: userIDKey) ?? Self.userIDs[0] }
        set { defaults.set(newValue, forKey: userIDKey) }
    }

    /// The full ledger of received referral codes, read from persistence.
    ///
    /// Always sourced from disk so callers never rely on stale in-memory state.
    var ledger: [ReferralCode] {
        guard let data = defaults.data(forKey: ledgerKey) else { return [] }
        return (try? JSONDecoder().decode([ReferralCode].self, from: data)) ?? []
    }

    /// The ledger entries the backend has not yet resolved.
    var unresolved: [ReferralCode] {
        ledger.filter { $0.status == .unresolved }
    }

    /// Records an incoming referral code with its metadata and persists it.
    ///
    /// A deep link is an explicit redemption attempt, so it is recorded again
    /// even for a code already resolved — re-using a code is how an invalid
    /// result (and the warning) is surfaced. The install conversion fires on
    /// every launch, so it is recorded only once per code.
    /// - Parameters:
    ///   - code: The referral code received from AppsFlyer.
    ///   - source: The listener that produced the code.
    func record(code: String, source: AnalyticsSource) {
        var ledger = ledger

        switch source {
        case .conversion:
            // Conversion fires on every app open, so only the first one per user
            // matters. A newly logged-in user still gets their own conversion.
            guard !ledger.contains(where: { $0.source == .conversion && $0.userID == userID }) else { return }
        case .deeplink:
            // Each deep link open is a fresh attempt, but the two AppsFlyer
            // deep link callbacks for a single open share one entry per user.
            guard !ledger.contains(where: { $0.code == code && $0.userID == userID && $0.status == .unresolved }) else { return }
        }

        let entry = ReferralCode(code: code, date: .now, source: source, userID: userID)
        ledger.append(entry)
        persist(ledger)
    }

    /// Resolves a ledger entry with the backend's eligibility verdict.
    /// - Parameters:
    ///   - id: The identifier of the entry to resolve.
    ///   - eligability: The backend's eligibility response.
    func resolve(id: UUID, eligability: Eligability) {
        var ledger = ledger
        guard let index = ledger.firstIndex(where: { $0.id == id }) else { return }

        ledger[index].status = .resolved(eligability)
        persist(ledger)
    }

    // MARK: - Private Helpers

    /// Persists the given ledger.
    private func persist(_ ledger: [ReferralCode]) {
        guard let data = try? JSONEncoder().encode(ledger) else { return }
        defaults.set(data, forKey: ledgerKey)
    }
}
