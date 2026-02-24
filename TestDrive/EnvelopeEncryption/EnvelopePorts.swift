import Foundation

/// Persistence interface for account-level root wraps and device enrollments.
protocol AccountMetadataRepository {
    func saveRootWraps(_ wraps: AccountRootWraps) throws
    func loadRootWraps(accountID: UUID) throws -> AccountRootWraps

    func saveDeviceEnrollment(_ enrollment: DeviceEnrollment) throws
    func loadDeviceEnrollment(accountID: UUID, deviceID: UUID) throws -> DeviceEnrollment
}

/// Tracking interface for recovery attempt throttling and lockout.
protocol RecoveryAttemptTracking {
    func checkAttemptAllowed(accountID: UUID) throws
    func recordFailure(accountID: UUID) throws
    func recordSuccess(accountID: UUID) throws
    func resetLockout(accountID: UUID) throws
}
