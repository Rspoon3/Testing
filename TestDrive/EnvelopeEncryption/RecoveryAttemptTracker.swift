import Foundation
import GRDB
import SQLiteData

/// Enforces brute-force protection on recovery code attempts.
///
/// Tracks consecutive failures per account in SQLite and applies exponential
/// backoff before allowing the next attempt. After a configurable maximum
/// number of failures the account is permanently locked until manually reset.
final class RecoveryAttemptTracker: RecoveryAttemptTracking {
    /// Errors thrown when a recovery attempt is blocked by the rate-limit policy.
    enum TrackerError: Error, Equatable {
        /// The caller must wait before retrying. `retryAfter` is the remaining delay in seconds.
        case rateLimited(retryAfter: TimeInterval)
        /// The account is permanently locked after exceeding the maximum allowed failures.
        case lockedOut(consecutiveFailures: Int)
    }

    /// Configurable policy for the brute-force protection window.
    struct Policy: Sendable {
        /// Base delay in seconds applied after the first failure. Doubles on each subsequent failure.
        var baseDelay: TimeInterval
        /// Maximum consecutive failures before permanently locking recovery for the account.
        var maxConsecutiveFailures: Int

        /// Default policy: 2-second base delay, locked after 10 consecutive failures.
        static let `default` = Policy(baseDelay: 2, maxConsecutiveFailures: 10)
    }

    /// Backing SQLite database (shared with the envelope store).
    let database: DatabaseQueue
    /// Active rate-limit policy.
    let policy: Policy
    /// Clock abstraction for testability.
    private let now: () -> Date

    // MARK: - Initializer

    /// Creates a tracker backed by the given database.
    /// - Parameters:
    ///   - database: SQLite database that contains the `recoveryAttemptRows` table.
    ///   - policy: Brute-force protection policy.
    ///   - now: Clock override for deterministic testing.
    init(
        database: DatabaseQueue,
        policy: Policy = .default,
        now: @escaping () -> Date = { Date() }
    ) {
        self.database = database
        self.policy = policy
        self.now = now
    }

    // MARK: - Public Helpers

    /// Checks whether a recovery attempt is currently allowed for the account.
    ///
    /// - Throws: ``TrackerError/rateLimited(retryAfter:)`` if the backoff window has not elapsed.
    /// - Throws: ``TrackerError/lockedOut(consecutiveFailures:)`` if the failure count exceeds the policy maximum.
    func checkAttemptAllowed(accountID: UUID) throws {
        guard let row = try loadRow(accountID: accountID) else { return }

        if row.consecutiveFailures >= policy.maxConsecutiveFailures {
            throw TrackerError.lockedOut(consecutiveFailures: row.consecutiveFailures)
        }

        let delay = backoffDelay(consecutiveFailures: row.consecutiveFailures)
        let elapsed = now().timeIntervalSince(row.lastAttemptAt)

        if elapsed < delay {
            throw TrackerError.rateLimited(retryAfter: delay - elapsed)
        }
    }

    /// Records a failed recovery attempt, incrementing the consecutive failure count.
    func recordFailure(accountID: UUID) throws {
        let current = try loadRow(accountID: accountID)
        let newFailures = (current?.consecutiveFailures ?? 0) + 1
        try upsertRow(accountID: accountID, consecutiveFailures: newFailures, lastAttemptAt: now())
    }

    /// Resets the failure counter after a successful recovery.
    func recordSuccess(accountID: UUID) throws {
        try deleteRow(accountID: accountID)
    }

    /// Manually resets the lockout for an account (for example after identity verification).
    func resetLockout(accountID: UUID) throws {
        try deleteRow(accountID: accountID)
    }

    // MARK: - Private Helpers

    /// Computes the backoff delay for a given failure count using exponential growth.
    ///
    /// Delay = `baseDelay * 2^(failures - 1)`:
    /// 1 failure → 2 s, 2 → 4 s, 3 → 8 s, 4 → 16 s, …
    private func backoffDelay(consecutiveFailures: Int) -> TimeInterval {
        guard consecutiveFailures > 0 else { return 0 }
        return policy.baseDelay * pow(2.0, Double(consecutiveFailures - 1))
    }

    private func loadRow(accountID: UUID) throws -> RecoveryAttemptRow? {
        try database.read { db in
            try RecoveryAttemptRow
                .where { $0.id.eq(accountID) }
                .fetchOne(db)
        }
    }

    private func upsertRow(accountID: UUID, consecutiveFailures: Int, lastAttemptAt: Date) throws {
        try database.write { db in
            try RecoveryAttemptRow
                .where { $0.id.eq(accountID) }
                .delete()
                .execute(db)

            try RecoveryAttemptRow.insert {
                RecoveryAttemptRow(
                    id: accountID,
                    consecutiveFailures: consecutiveFailures,
                    lastAttemptAt: lastAttemptAt
                )
            }
            .execute(db)
        }
    }

    private func deleteRow(accountID: UUID) throws {
        try database.write { db in
            try RecoveryAttemptRow
                .where { $0.id.eq(accountID) }
                .delete()
                .execute(db)
        }
    }
}
