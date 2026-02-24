import CryptoKit
import Dependencies
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
        let dependencies = makeInMemoryCoordinatorDependencies()

        let bootstrap = try withCoordinatorDependencies(dependencies) {
            try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: recoveryCode,
                initialDeviceID: deviceID,
                initialDeviceWrapKey: deviceWrapKey
            )
        }
        let unlockedARK = try withCoordinatorDependencies(dependencies) {
            try AccountKeyCoordinator.unlockARKForDevice(
                accountID: accountID,
                deviceID: deviceID,
                deviceWrapKey: deviceWrapKey
            )
        }

        #expect(keyMaterial(unlockedARK) == keyMaterial(bootstrap.ark))
        let storedAccountID = dependencies.metadataState.withValue { state in
            state.rootWrapsByAccountID[accountID]?.accountID
        }
        #expect(storedAccountID == accountID)
    }

    @Test
    func recoverySuccessRecordsTrackerSuccessWithoutSQLite() throws {
        let accountID = UUID()
        let deviceID = UUID()
        let recoveryCode = "correct horse battery staple"
        let dependencies = makeInMemoryCoordinatorDependencies()

        let bootstrap = try withCoordinatorDependencies(dependencies) {
            try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: recoveryCode,
                initialDeviceID: deviceID,
                initialDeviceWrapKey: SymmetricKey(size: .bits256)
            )
        }
        let recoveredARK = try withCoordinatorDependencies(dependencies) {
            try AccountKeyCoordinator.recoverARK(
                accountID: accountID,
                recoveryCode: recoveryCode
            )
        }

        let trackerState = dependencies.trackerState.withValue { $0 }
        #expect(keyMaterial(recoveredARK) == keyMaterial(bootstrap.ark))
        #expect(trackerState.checkCalls == [accountID])
        #expect(trackerState.successCalls == [accountID])
        #expect(trackerState.failureCalls.isEmpty)
    }

    @Test
    func recoveryFailureRecordsTrackerFailureWithoutSQLite() throws {
        let accountID = UUID()
        let deviceID = UUID()
        let dependencies = makeInMemoryCoordinatorDependencies()

        _ = try withCoordinatorDependencies(dependencies) {
            try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: "correct horse battery staple",
                initialDeviceID: deviceID,
                initialDeviceWrapKey: SymmetricKey(size: .bits256)
            )
        }

        #expect(throws: (any Error).self) {
            try withCoordinatorDependencies(dependencies) {
                try AccountKeyCoordinator.recoverARK(
                    accountID: accountID,
                    recoveryCode: "wrong code"
                )
            }
        }

        let trackerState = dependencies.trackerState.withValue { $0 }
        #expect(trackerState.checkCalls == [accountID])
        #expect(trackerState.successCalls.isEmpty)
        #expect(trackerState.failureCalls == [accountID])
    }

    @Test
    func trackerRejectionShortCircuitsRecovery() throws {
        let accountID = UUID()
        let deviceID = UUID()
        let dependencies = makeInMemoryCoordinatorDependencies()
        dependencies.trackerState.withValue { $0.shouldThrowOnCheck = true }

        _ = try withCoordinatorDependencies(dependencies) {
            try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: "correct horse battery staple",
                initialDeviceID: deviceID,
                initialDeviceWrapKey: SymmetricKey(size: .bits256)
            )
        }

        #expect(throws: TrackerStubError.self) {
            try withCoordinatorDependencies(dependencies) {
                try AccountKeyCoordinator.recoverARK(
                    accountID: accountID,
                    recoveryCode: "correct horse battery staple"
                )
            }
        }

        let trackerState = dependencies.trackerState.withValue { $0 }
        #expect(trackerState.checkCalls == [accountID])
        #expect(trackerState.successCalls.isEmpty)
        #expect(trackerState.failureCalls.isEmpty)
    }
}

private struct InMemoryCoordinatorDependencies {
    let metadataState: LockedValue<InMemoryMetadataState>
    let trackerState: LockedValue<TrackerProbeState>

    var metadataClient: AccountMetadataClient {
        makeAccountMetadataClient(state: metadataState)
    }

    var trackerClient: RecoveryAttemptTrackerClient {
        makeRecoveryAttemptTrackerClient(state: trackerState)
    }
}

private struct InMemoryMetadataState {
    var rootWrapsByAccountID: [UUID: AccountRootWraps] = [:]
    var enrollmentsByAccountAndDeviceID: [DeviceEnrollmentKey: DeviceEnrollment] = [:]
}

private struct TrackerProbeState: Sendable {
    var shouldThrowOnCheck = false
    var checkCalls: [UUID] = []
    var failureCalls: [UUID] = []
    var successCalls: [UUID] = []
    var resetCalls: [UUID] = []
}

private struct DeviceEnrollmentKey: Hashable {
    let accountID: UUID
    let deviceID: UUID
}

private enum InMemoryMetadataError: Error {
    case accountNotFound
    case deviceEnrollmentNotFound
}

private enum TrackerStubError: Error {
    case blocked
}

private func makeInMemoryCoordinatorDependencies() -> InMemoryCoordinatorDependencies {
    InMemoryCoordinatorDependencies(
        metadataState: LockedValue(InMemoryMetadataState()),
        trackerState: LockedValue(TrackerProbeState())
    )
}

private func makeAccountMetadataClient(state: LockedValue<InMemoryMetadataState>) -> AccountMetadataClient {
    AccountMetadataClient(
        saveRootWraps: { wraps in
            state.withValue { $0.rootWrapsByAccountID[wraps.accountID] = wraps }
        },
        loadRootWraps: { accountID in
            try state.withValue { state in
                guard let wraps = state.rootWrapsByAccountID[accountID] else {
                    throw InMemoryMetadataError.accountNotFound
                }
                return wraps
            }
        },
        saveDeviceEnrollment: { enrollment in
            state.withValue {
                $0.enrollmentsByAccountAndDeviceID[
                    DeviceEnrollmentKey(accountID: enrollment.accountID, deviceID: enrollment.deviceID)
                ] = enrollment
            }
        },
        loadDeviceEnrollment: { accountID, deviceID in
            try state.withValue { state in
                guard let enrollment = state.enrollmentsByAccountAndDeviceID[
                    DeviceEnrollmentKey(accountID: accountID, deviceID: deviceID)
                ] else {
                    throw InMemoryMetadataError.deviceEnrollmentNotFound
                }
                return enrollment
            }
        }
    )
}

private func makeRecoveryAttemptTrackerClient(
    state: LockedValue<TrackerProbeState>
) -> RecoveryAttemptTrackerClient {
    RecoveryAttemptTrackerClient(
        checkAttemptAllowed: { accountID in
            try state.withValue { state in
                state.checkCalls.append(accountID)
                if state.shouldThrowOnCheck {
                    throw TrackerStubError.blocked
                }
            }
        },
        recordFailure: { accountID in
            state.withValue { $0.failureCalls.append(accountID) }
        },
        recordSuccess: { accountID in
            state.withValue { $0.successCalls.append(accountID) }
        },
        resetLockout: { accountID in
            state.withValue { $0.resetCalls.append(accountID) }
        }
    )
}

private func withCoordinatorDependencies<R>(
    _ dependencies: InMemoryCoordinatorDependencies,
    operation: () throws -> R
) rethrows -> R {
    try withDependencies {
        $0.accountMetadata = dependencies.metadataClient
        $0.recoveryAttemptTracker = dependencies.trackerClient
    } operation: {
        try operation()
    }
}

private func keyMaterial(_ key: SymmetricKey) -> Data {
    key.withUnsafeBytes { Data($0) }
}

private final class LockedValue<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func withValue<T>(_ operation: (inout Value) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try operation(&value)
    }
}
