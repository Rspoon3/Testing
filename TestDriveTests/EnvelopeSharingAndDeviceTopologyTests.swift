import CryptoKit
import Dependencies
import Foundation
import Testing
@testable import TestDrive

struct EnvelopeSharingAndDeviceTopologyTests {
    @Test
    func ownerDevicesABCCanReadAndEditCredentialWithoutSQLite() throws {
        let accountID = UUID()
        let recoveryCode = "correct horse battery staple"
        let dependencies = makeInMemoryCoordinatorDependencies()
        let sharedPersistence = makeInMemoryEnvelopeDomainPersistence()

        try withCoordinatorDependencies(dependencies) {
            let deviceAID = UUID()
            let deviceAWrapKey = SymmetricKey(size: .bits256)
            _ = try AccountKeyCoordinator.bootstrapAccount(
                accountID: accountID,
                recoveryCode: recoveryCode,
                initialDeviceID: deviceAID,
                initialDeviceWrapKey: deviceAWrapKey
            )
            let arkOnA = try AccountKeyCoordinator.unlockARKForDevice(
                accountID: accountID,
                deviceID: deviceAID,
                deviceWrapKey: deviceAWrapKey
            )
            let storeA = makeEnvelopeDomainStore(
                persistence: sharedPersistence,
                ark: arkOnA,
                arkKeyID: EnvelopeKeyID.accountARK(accountID: accountID)
            )

            let vaultID = try storeA.createVault(name: "Primary")
            let created = try storeA.createCredential(
                vaultID: vaultID,
                label: "Stripe",
                type: .personalAccessToken,
                initialSecretLabel: "token",
                initialSecretPlaintext: Data("pat_a_initial".utf8)
            )

            let recoveredARK = try AccountKeyCoordinator.recoverARK(
                accountID: accountID,
                recoveryCode: recoveryCode
            )

            let deviceBID = UUID()
            let deviceBWrapKey = SymmetricKey(size: .bits256)
            _ = try AccountKeyCoordinator.enrollDevice(
                accountID: accountID,
                ark: recoveredARK,
                deviceID: deviceBID,
                deviceWrapKey: deviceBWrapKey
            )
            let arkOnB = try AccountKeyCoordinator.unlockARKForDevice(
                accountID: accountID,
                deviceID: deviceBID,
                deviceWrapKey: deviceBWrapKey
            )
            let storeB = makeEnvelopeDomainStore(
                persistence: sharedPersistence,
                ark: arkOnB,
                arkKeyID: EnvelopeKeyID.accountARK(accountID: accountID)
            )

            let deviceCID = UUID()
            let deviceCWrapKey = SymmetricKey(size: .bits256)
            _ = try AccountKeyCoordinator.enrollDevice(
                accountID: accountID,
                ark: recoveredARK,
                deviceID: deviceCID,
                deviceWrapKey: deviceCWrapKey
            )
            let arkOnC = try AccountKeyCoordinator.unlockARKForDevice(
                accountID: accountID,
                deviceID: deviceCID,
                deviceWrapKey: deviceCWrapKey
            )
            let storeC = makeEnvelopeDomainStore(
                persistence: sharedPersistence,
                ark: arkOnC,
                arkKeyID: EnvelopeKeyID.accountARK(accountID: accountID)
            )

            let initialOnB = try storeB.revealSecret(secretID: created.initialSecretFieldID)
            let initialOnC = try storeC.revealSecret(secretID: created.initialSecretFieldID)
            #expect(String(decoding: initialOnB, as: UTF8.self) == "pat_a_initial")
            #expect(String(decoding: initialOnC, as: UTF8.self) == "pat_a_initial")

            let rotatedID = try storeB.addSecret(
                credentialID: created.credentialID,
                name: "tokenRotated",
                plaintext: Data("pat_b_rotated".utf8)
            )

            let rotatedOnA = try storeA.revealSecret(secretID: rotatedID)
            let rotatedOnC = try storeC.revealSecret(secretID: rotatedID)
            #expect(String(decoding: rotatedOnA, as: UTF8.self) == "pat_b_rotated")
            #expect(String(decoding: rotatedOnC, as: UTF8.self) == "pat_b_rotated")
        }
    }

    @Test
    func userASharesWithUserBWithoutSQLite() throws {
        let userA = try makeUserContext()
        let userB = try makeUserContext()

        let storeA = makeEnvelopeDomainStore(
            persistence: userA.persistence,
            ark: userA.ark,
            arkKeyID: EnvelopeKeyID.accountARK(accountID: userA.accountID)
        )
        let storeB = makeEnvelopeDomainStore(
            persistence: userB.persistence,
            ark: userB.ark,
            arkKeyID: EnvelopeKeyID.accountARK(accountID: userB.accountID)
        )

        let vaultID = try storeA.createVault(name: "Shared Vault")
        let created = try storeA.createCredential(
            vaultID: vaultID,
            label: "CI Token",
            type: .personalAccessToken,
            initialSecretLabel: "token",
            initialSecretPlaintext: Data("pat_shared_from_a".utf8)
        )

        #expect(
            SharedVaultProvisioningPolicy.canProvision(
                actorRole: .owner,
                actorPrincipalID: userA.accountID,
                targetPrincipalID: userB.accountID
            )
        )

        let packageForB = try storeA.makeSharedVaultPackage(
            vaultID: vaultID,
            recipientARK: userB.ark,
            recipientARKKeyID: EnvelopeKeyID.accountARK(accountID: userB.accountID)
        )
        try storeB.importSharedVaultPackage(packageForB)

        let revealedOnB = try storeB.revealSecret(secretID: created.initialSecretFieldID)
        #expect(String(decoding: revealedOnB, as: UTF8.self) == "pat_shared_from_a")
    }

    @Test
    func userBEditsSharedCredentialAndUserAReceivesUpdateWithoutSQLite() throws {
        let userA = try makeUserContext()
        let userB = try makeUserContext()

        let storeA = makeEnvelopeDomainStore(
            persistence: userA.persistence,
            ark: userA.ark,
            arkKeyID: EnvelopeKeyID.accountARK(accountID: userA.accountID)
        )
        let storeB = makeEnvelopeDomainStore(
            persistence: userB.persistence,
            ark: userB.ark,
            arkKeyID: EnvelopeKeyID.accountARK(accountID: userB.accountID)
        )

        let vaultID = try storeA.createVault(name: "Shared Edit Vault")
        let created = try storeA.createCredential(
            vaultID: vaultID,
            label: "Deploy Key",
            type: .sshKey,
            initialSecretLabel: "privateKey",
            initialSecretPlaintext: Data("ssh-rsa AAAA-user-a".utf8)
        )

        let packageForB = try storeA.makeSharedVaultPackage(
            vaultID: vaultID,
            recipientARK: userB.ark,
            recipientARKKeyID: EnvelopeKeyID.accountARK(accountID: userB.accountID)
        )
        try storeB.importSharedVaultPackage(packageForB)
        let newSecretID = try storeB.addSecret(
            credentialID: created.credentialID,
            name: "passphrase",
            plaintext: Data("rotated-passphrase-by-b".utf8)
        )

        let packageBackToA = try storeB.makeSharedVaultPackage(
            vaultID: vaultID,
            recipientARK: userA.ark,
            recipientARKKeyID: EnvelopeKeyID.accountARK(accountID: userA.accountID)
        )
        try storeA.importSharedVaultPackage(packageBackToA)

        let revealedOnA = try storeA.revealSecret(secretID: newSecretID)
        #expect(String(decoding: revealedOnA, as: UTF8.self) == "rotated-passphrase-by-b")
    }
}

private struct UserContext {
    let accountID: UUID
    let ark: SymmetricKey
    let persistence: InMemoryEnvelopeDomainPersistence
}

private func makeUserContext() throws -> UserContext {
    let accountID = UUID()
    let dependencies = makeInMemoryCoordinatorDependencies()
    let persistence = makeInMemoryEnvelopeDomainPersistence()
    let deviceID = UUID()
    let deviceWrapKey = SymmetricKey(size: .bits256)

    let ark = try withCoordinatorDependencies(dependencies) {
        _ = try AccountKeyCoordinator.bootstrapAccount(
            accountID: accountID,
            recoveryCode: "correct horse battery staple",
            initialDeviceID: deviceID,
            initialDeviceWrapKey: deviceWrapKey
        )
        return try AccountKeyCoordinator.unlockARKForDevice(
            accountID: accountID,
            deviceID: deviceID,
            deviceWrapKey: deviceWrapKey
        )
    }

    return UserContext(
        accountID: accountID,
        ark: ark,
        persistence: persistence
    )
}

private typealias InMemoryEnvelopeDomainPersistence = LockedValue<InMemoryEnvelopeDomainPersistenceState>

private struct InMemoryEnvelopeDomainPersistenceState {
    var vaultsByID: [UUID: PersistedVault] = [:]
    var credentialsByID: [UUID: PersistedCredential] = [:]
    var secretFieldsByID: [UUID: PersistedSecretField] = [:]
}

private enum InMemoryEnvelopePersistenceError: Error {
    case vaultNotFound
    case credentialNotFound
    case secretFieldNotFound
}

private func makeInMemoryEnvelopeDomainPersistence() -> InMemoryEnvelopeDomainPersistence {
    LockedValue(InMemoryEnvelopeDomainPersistenceState())
}

private func makeEnvelopeDomainPersistenceClient(
    persistence: InMemoryEnvelopeDomainPersistence
) -> EnvelopeDomainPersistenceClient {
    EnvelopeDomainPersistenceClient(
        upsertVault: { vault in
            persistence.withValue { $0.vaultsByID[vault.id] = vault }
        },
        loadVault: { id in
            try persistence.withValue { state in
                guard let vault = state.vaultsByID[id] else {
                    throw InMemoryEnvelopePersistenceError.vaultNotFound
                }
                return vault
            }
        },
        fetchVault: { id in
            persistence.withValue { $0.vaultsByID[id] }
        },
        upsertCredential: { credential in
            persistence.withValue { $0.credentialsByID[credential.id] = credential }
        },
        upsertCredentialWithInitialSecret: { credential, initialSecretField in
            persistence.withValue {
                $0.credentialsByID[credential.id] = credential
                $0.secretFieldsByID[initialSecretField.id] = initialSecretField
            }
        },
        loadCredential: { id in
            try persistence.withValue { state in
                guard let credential = state.credentialsByID[id] else {
                    throw InMemoryEnvelopePersistenceError.credentialNotFound
                }
                return credential
            }
        },
        fetchCredential: { id in
            persistence.withValue { $0.credentialsByID[id] }
        },
        loadCredentials: { vaultID in
            persistence.withValue { state in
                state.credentialsByID.values
                    .filter { $0.vaultID == vaultID }
                    .sorted { $0.createdAt < $1.createdAt }
            }
        },
        upsertSecretField: { field in
            persistence.withValue { $0.secretFieldsByID[field.id] = field }
        },
        loadSecretField: { id in
            try persistence.withValue { state in
                guard let field = state.secretFieldsByID[id] else {
                    throw InMemoryEnvelopePersistenceError.secretFieldNotFound
                }
                return field
            }
        },
        loadSecretFields: { itemID in
            persistence.withValue { state in
                state.secretFieldsByID.values
                    .filter { $0.itemID == itemID }
                    .sorted { $0.createdAt < $1.createdAt }
            }
        }
    )
}

private func makeEnvelopeDomainStore(
    persistence: InMemoryEnvelopeDomainPersistence,
    ark: SymmetricKey,
    arkKeyID: String
) -> EnvelopeDomainStore {
    withDependencies {
        $0.envelopeDomainPersistence = makeEnvelopeDomainPersistenceClient(persistence: persistence)
    } operation: {
        EnvelopeDomainStore(
            ark: ark,
            arkKeyID: arkKeyID
        )
    }
}

private struct InMemoryCoordinatorDependencies {
    let metadataState: LockedValue<InMemoryMetadataState>
    let trackerState: LockedValue<TrackerState>

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

private struct TrackerState: Sendable {
    var consecutiveFailuresByAccountID: [UUID: Int] = [:]
}

private struct DeviceEnrollmentKey: Hashable {
    let accountID: UUID
    let deviceID: UUID
}

private enum InMemoryMetadataError: Error {
    case accountNotFound
    case deviceEnrollmentNotFound
}

private func makeInMemoryCoordinatorDependencies() -> InMemoryCoordinatorDependencies {
    InMemoryCoordinatorDependencies(
        metadataState: LockedValue(InMemoryMetadataState()),
        trackerState: LockedValue(TrackerState())
    )
}

private func makeAccountMetadataClient(state: LockedValue<InMemoryMetadataState>) -> AccountMetadataClient {
    AccountMetadataClient(
        saveBootstrap: { wraps, enrollment in
            state.withValue {
                $0.rootWrapsByAccountID[wraps.accountID] = wraps
                $0.enrollmentsByAccountAndDeviceID[
                    DeviceEnrollmentKey(accountID: enrollment.accountID, deviceID: enrollment.deviceID)
                ] = enrollment
            }
        },
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
    state: LockedValue<TrackerState>
) -> RecoveryAttemptTrackerClient {
    RecoveryAttemptTrackerClient(
        checkAttemptAllowed: { _ in },
        recordFailure: { accountID in
            state.withValue { $0.consecutiveFailuresByAccountID[accountID, default: 0] += 1 }
        },
        recordSuccess: { accountID in
            state.withValue { $0.consecutiveFailuresByAccountID[accountID] = 0 }
        },
        resetLockout: { accountID in
            state.withValue { $0.consecutiveFailuresByAccountID[accountID] = 0 }
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
