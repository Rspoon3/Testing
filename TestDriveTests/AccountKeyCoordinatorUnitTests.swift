import CryptoKit
import Foundation
import Testing
@testable import TestDrive

struct AccountKeyCoordinatorUnitTests {
    @Test
    func bootstrapAndDeviceUnlockWithoutSQLite() throws {
        let accountID = UUID()
        let deviceID = UUID()
        let recoveryCode = "correct horse battery staple"
        let deviceWrapKey = SymmetricKey(size: .bits256)
        let metadataRepository = InMemoryAccountMetadataRepository()

        let bootstrap = try AccountKeyCoordinator.bootstrapAccount(
            accountID: accountID,
            recoveryCode: recoveryCode,
            initialDeviceID: deviceID,
            initialDeviceWrapKey: deviceWrapKey,
            metadataStore: metadataRepository
        )
        let unlockedARK = try AccountKeyCoordinator.unlockARKForDevice(
            metadataStore: metadataRepository,
            accountID: accountID,
            deviceID: deviceID,
            deviceWrapKey: deviceWrapKey
        )

        #expect(keyMaterial(unlockedARK) == keyMaterial(bootstrap.ark))
        #expect((try? metadataRepository.loadRootWraps(accountID: accountID).accountID) == accountID)
    }

    @Test
    func recoverySuccessRecordsTrackerSuccessWithoutSQLite() throws {
        let accountID = UUID()
        let deviceID = UUID()
        let recoveryCode = "correct horse battery staple"
        let metadataRepository = InMemoryAccountMetadataRepository()
        let tracker = SpyRecoveryAttemptTracker()

        let bootstrap = try AccountKeyCoordinator.bootstrapAccount(
            accountID: accountID,
            recoveryCode: recoveryCode,
            initialDeviceID: deviceID,
            initialDeviceWrapKey: SymmetricKey(size: .bits256),
            metadataStore: metadataRepository
        )
        let recoveredARK = try AccountKeyCoordinator.recoverARK(
            metadataStore: metadataRepository,
            accountID: accountID,
            recoveryCode: recoveryCode,
            attemptTracker: tracker
        )

        #expect(keyMaterial(recoveredARK) == keyMaterial(bootstrap.ark))
        #expect(tracker.checkCalls == [accountID])
        #expect(tracker.successCalls == [accountID])
        #expect(tracker.failureCalls.isEmpty)
    }

    @Test
    func recoveryFailureRecordsTrackerFailureWithoutSQLite() throws {
        let accountID = UUID()
        let deviceID = UUID()
        let metadataRepository = InMemoryAccountMetadataRepository()
        let tracker = SpyRecoveryAttemptTracker()

        _ = try AccountKeyCoordinator.bootstrapAccount(
            accountID: accountID,
            recoveryCode: "correct horse battery staple",
            initialDeviceID: deviceID,
            initialDeviceWrapKey: SymmetricKey(size: .bits256),
            metadataStore: metadataRepository
        )

        #expect(throws: (any Error).self) {
            try AccountKeyCoordinator.recoverARK(
                metadataStore: metadataRepository,
                accountID: accountID,
                recoveryCode: "wrong code",
                attemptTracker: tracker
            )
        }

        #expect(tracker.checkCalls == [accountID])
        #expect(tracker.successCalls.isEmpty)
        #expect(tracker.failureCalls == [accountID])
    }

    @Test
    func trackerRejectionShortCircuitsRecovery() throws {
        let accountID = UUID()
        let deviceID = UUID()
        let metadataRepository = InMemoryAccountMetadataRepository()
        let tracker = SpyRecoveryAttemptTracker()
        tracker.shouldThrowOnCheck = true

        _ = try AccountKeyCoordinator.bootstrapAccount(
            accountID: accountID,
            recoveryCode: "correct horse battery staple",
            initialDeviceID: deviceID,
            initialDeviceWrapKey: SymmetricKey(size: .bits256),
            metadataStore: metadataRepository
        )

        #expect(throws: SpyRecoveryAttemptTracker.StubError.self) {
            try AccountKeyCoordinator.recoverARK(
                metadataStore: metadataRepository,
                accountID: accountID,
                recoveryCode: "correct horse battery staple",
                attemptTracker: tracker
            )
        }

        #expect(tracker.checkCalls == [accountID])
        #expect(tracker.successCalls.isEmpty)
        #expect(tracker.failureCalls.isEmpty)
    }
}

private func keyMaterial(_ key: SymmetricKey) -> Data {
    key.withUnsafeBytes { Data($0) }
}

private final class InMemoryAccountMetadataRepository: AccountMetadataRepository {
    enum RepositoryError: Error {
        case accountNotFound
        case deviceEnrollmentNotFound
    }

    private var rootWrapsByAccountID: [UUID: AccountRootWraps] = [:]
    private var enrollmentsByAccountAndDeviceID: [DeviceEnrollmentKey: DeviceEnrollment] = [:]

    func saveRootWraps(_ wraps: AccountRootWraps) throws {
        rootWrapsByAccountID[wraps.accountID] = wraps
    }

    func loadRootWraps(accountID: UUID) throws -> AccountRootWraps {
        guard let wraps = rootWrapsByAccountID[accountID] else {
            throw RepositoryError.accountNotFound
        }
        return wraps
    }

    func saveDeviceEnrollment(_ enrollment: DeviceEnrollment) throws {
        enrollmentsByAccountAndDeviceID[
            DeviceEnrollmentKey(accountID: enrollment.accountID, deviceID: enrollment.deviceID)
        ] = enrollment
    }

    func loadDeviceEnrollment(accountID: UUID, deviceID: UUID) throws -> DeviceEnrollment {
        guard let enrollment = enrollmentsByAccountAndDeviceID[
            DeviceEnrollmentKey(accountID: accountID, deviceID: deviceID)
        ] else {
            throw RepositoryError.deviceEnrollmentNotFound
        }
        return enrollment
    }
}

private struct DeviceEnrollmentKey: Hashable {
    let accountID: UUID
    let deviceID: UUID
}

private final class SpyRecoveryAttemptTracker: RecoveryAttemptTracking {
    enum StubError: Error {
        case blocked
    }

    var shouldThrowOnCheck = false

    private(set) var checkCalls: [UUID] = []
    private(set) var failureCalls: [UUID] = []
    private(set) var successCalls: [UUID] = []
    private(set) var resetCalls: [UUID] = []

    func checkAttemptAllowed(accountID: UUID) throws {
        checkCalls.append(accountID)
        if shouldThrowOnCheck {
            throw StubError.blocked
        }
    }

    func recordFailure(accountID: UUID) throws {
        failureCalls.append(accountID)
    }

    func recordSuccess(accountID: UUID) throws {
        successCalls.append(accountID)
    }

    func resetLockout(accountID: UUID) throws {
        resetCalls.append(accountID)
    }
}
