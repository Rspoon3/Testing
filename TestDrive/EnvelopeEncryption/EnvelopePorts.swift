import Dependencies
import Foundation

struct AccountMetadataClient: Sendable {
    var saveBootstrap: @Sendable (_ wraps: AccountRootWraps, _ enrollment: DeviceEnrollment) throws -> Void
    var saveRootWraps: @Sendable (_ wraps: AccountRootWraps) throws -> Void
    var loadRootWraps: @Sendable (_ accountID: UUID) throws -> AccountRootWraps
    var saveDeviceEnrollment: @Sendable (_ enrollment: DeviceEnrollment) throws -> Void
    var loadDeviceEnrollment: @Sendable (_ accountID: UUID, _ deviceID: UUID) throws -> DeviceEnrollment
}

struct RecoveryAttemptTrackerClient: Sendable {
    var checkAttemptAllowed: @Sendable (_ accountID: UUID) throws -> Void
    var recordFailure: @Sendable (_ accountID: UUID) throws -> Void
    var recordSuccess: @Sendable (_ accountID: UUID) throws -> Void
    var resetLockout: @Sendable (_ accountID: UUID) throws -> Void
}

extension AccountMetadataClient: DependencyKey {
    static var liveValue: AccountMetadataClient {
        .unimplemented
    }

    static var testValue: AccountMetadataClient {
        .unimplemented
    }
}

extension RecoveryAttemptTrackerClient: DependencyKey {
    static var liveValue: RecoveryAttemptTrackerClient {
        .unimplemented
    }

    static var testValue: RecoveryAttemptTrackerClient {
        .unimplemented
    }
}

extension DependencyValues {
    var accountMetadata: AccountMetadataClient {
        get { self[AccountMetadataClient.self] }
        set { self[AccountMetadataClient.self] = newValue }
    }

    var recoveryAttemptTracker: RecoveryAttemptTrackerClient {
        get { self[RecoveryAttemptTrackerClient.self] }
        set { self[RecoveryAttemptTrackerClient.self] = newValue }
    }
}

extension AccountMetadataClient {
    static var unimplemented: AccountMetadataClient {
        AccountMetadataClient(
            saveBootstrap: { _, _ in throw DependencyNotConfiguredError(endpoint: "accountMetadata.saveBootstrap") },
            saveRootWraps: { _ in throw DependencyNotConfiguredError(endpoint: "accountMetadata.saveRootWraps") },
            loadRootWraps: { _ in throw DependencyNotConfiguredError(endpoint: "accountMetadata.loadRootWraps") },
            saveDeviceEnrollment: { _ in
                throw DependencyNotConfiguredError(endpoint: "accountMetadata.saveDeviceEnrollment")
            },
            loadDeviceEnrollment: { _, _ in
                throw DependencyNotConfiguredError(endpoint: "accountMetadata.loadDeviceEnrollment")
            }
        )
    }
}

extension RecoveryAttemptTrackerClient {
    static var unimplemented: RecoveryAttemptTrackerClient {
        RecoveryAttemptTrackerClient(
            checkAttemptAllowed: { _ in
                throw DependencyNotConfiguredError(endpoint: "recoveryAttemptTracker.checkAttemptAllowed")
            },
            recordFailure: { _ in
                throw DependencyNotConfiguredError(endpoint: "recoveryAttemptTracker.recordFailure")
            },
            recordSuccess: { _ in
                throw DependencyNotConfiguredError(endpoint: "recoveryAttemptTracker.recordSuccess")
            },
            resetLockout: { _ in
                throw DependencyNotConfiguredError(endpoint: "recoveryAttemptTracker.resetLockout")
            }
        )
    }
}

struct DependencyNotConfiguredError: Error {
    let endpoint: String
}
