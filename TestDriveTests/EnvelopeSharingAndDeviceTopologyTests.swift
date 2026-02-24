import CryptoKit
import Foundation
import Testing
@testable import TestDrive

struct EnvelopeSharingAndDeviceTopologyTests {
    @Test
    func ownerDevicesABCCanReadAndEditCredentialWithoutSQLite() throws {
        let accountID = UUID()
        let recoveryCode = "correct horse battery staple"
        let metadataRepository = InMemoryAccountMetadataRepository()
        let attemptTracker = InMemoryRecoveryAttemptTracker()
        let sharedPersistence = InMemoryEnvelopeDomainPersistence()

        let deviceAID = UUID()
        let deviceAWrapKey = SymmetricKey(size: .bits256)
        _ = try AccountKeyCoordinator.bootstrapAccount(
            accountID: accountID,
            recoveryCode: recoveryCode,
            initialDeviceID: deviceAID,
            initialDeviceWrapKey: deviceAWrapKey,
            metadataStore: metadataRepository
        )
        let arkOnA = try AccountKeyCoordinator.unlockARKForDevice(
            metadataStore: metadataRepository,
            accountID: accountID,
            deviceID: deviceAID,
            deviceWrapKey: deviceAWrapKey
        )
        let storeA = EnvelopeDomainStore(
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
            metadataStore: metadataRepository,
            accountID: accountID,
            recoveryCode: recoveryCode,
            attemptTracker: attemptTracker
        )

        let deviceBID = UUID()
        let deviceBWrapKey = SymmetricKey(size: .bits256)
        _ = try AccountKeyCoordinator.enrollDevice(
            metadataStore: metadataRepository,
            accountID: accountID,
            ark: recoveredARK,
            deviceID: deviceBID,
            deviceWrapKey: deviceBWrapKey
        )
        let arkOnB = try AccountKeyCoordinator.unlockARKForDevice(
            metadataStore: metadataRepository,
            accountID: accountID,
            deviceID: deviceBID,
            deviceWrapKey: deviceBWrapKey
        )
        let storeB = EnvelopeDomainStore(
            persistence: sharedPersistence,
            ark: arkOnB,
            arkKeyID: EnvelopeKeyID.accountARK(accountID: accountID)
        )

        let deviceCID = UUID()
        let deviceCWrapKey = SymmetricKey(size: .bits256)
        _ = try AccountKeyCoordinator.enrollDevice(
            metadataStore: metadataRepository,
            accountID: accountID,
            ark: recoveredARK,
            deviceID: deviceCID,
            deviceWrapKey: deviceCWrapKey
        )
        let arkOnC = try AccountKeyCoordinator.unlockARKForDevice(
            metadataStore: metadataRepository,
            accountID: accountID,
            deviceID: deviceCID,
            deviceWrapKey: deviceCWrapKey
        )
        let storeC = EnvelopeDomainStore(
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

    @Test
    func userASharesWithUserBWithoutSQLite() throws {
        let userA = try makeUserContext()
        let userB = try makeUserContext()

        let storeA = EnvelopeDomainStore(
            persistence: userA.persistence,
            ark: userA.ark,
            arkKeyID: EnvelopeKeyID.accountARK(accountID: userA.accountID)
        )
        let storeB = EnvelopeDomainStore(
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

        let storeA = EnvelopeDomainStore(
            persistence: userA.persistence,
            ark: userA.ark,
            arkKeyID: EnvelopeKeyID.accountARK(accountID: userA.accountID)
        )
        let storeB = EnvelopeDomainStore(
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
    let metadataRepository = InMemoryAccountMetadataRepository()
    let deviceID = UUID()
    let deviceWrapKey = SymmetricKey(size: .bits256)

    _ = try AccountKeyCoordinator.bootstrapAccount(
        accountID: accountID,
        recoveryCode: "correct horse battery staple",
        initialDeviceID: deviceID,
        initialDeviceWrapKey: deviceWrapKey,
        metadataStore: metadataRepository
    )
    let ark = try AccountKeyCoordinator.unlockARKForDevice(
        metadataStore: metadataRepository,
        accountID: accountID,
        deviceID: deviceID,
        deviceWrapKey: deviceWrapKey
    )

    return UserContext(
        accountID: accountID,
        ark: ark,
        persistence: InMemoryEnvelopeDomainPersistence()
    )
}

private final class InMemoryEnvelopeDomainPersistence: EnvelopeDomainPersisting {
    enum PersistenceError: Error {
        case vaultNotFound
        case credentialNotFound
        case secretFieldNotFound
    }

    private var vaultsByID: [UUID: PersistedVault] = [:]
    private var credentialsByID: [UUID: PersistedCredential] = [:]
    private var secretFieldsByID: [UUID: PersistedSecretField] = [:]

    func upsertVault(_ vault: PersistedVault) throws {
        vaultsByID[vault.id] = vault
    }

    func loadVault(id: UUID) throws -> PersistedVault {
        guard let vault = vaultsByID[id] else {
            throw PersistenceError.vaultNotFound
        }
        return vault
    }

    func fetchVault(id: UUID) throws -> PersistedVault? {
        vaultsByID[id]
    }

    func upsertCredential(_ credential: PersistedCredential) throws {
        credentialsByID[credential.id] = credential
    }

    func loadCredential(id: UUID) throws -> PersistedCredential {
        guard let credential = credentialsByID[id] else {
            throw PersistenceError.credentialNotFound
        }
        return credential
    }

    func fetchCredential(id: UUID) throws -> PersistedCredential? {
        credentialsByID[id]
    }

    func loadCredentials(vaultID: UUID) throws -> [PersistedCredential] {
        credentialsByID.values
            .filter { $0.vaultID == vaultID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func upsertSecretField(_ field: PersistedSecretField) throws {
        secretFieldsByID[field.id] = field
    }

    func loadSecretField(id: UUID) throws -> PersistedSecretField {
        guard let field = secretFieldsByID[id] else {
            throw PersistenceError.secretFieldNotFound
        }
        return field
    }

    func loadSecretFields(itemID: UUID) throws -> [PersistedSecretField] {
        secretFieldsByID.values
            .filter { $0.itemID == itemID }
            .sorted { $0.createdAt < $1.createdAt }
    }
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

private final class InMemoryRecoveryAttemptTracker: RecoveryAttemptTracking {
    private var consecutiveFailuresByAccountID: [UUID: Int] = [:]

    func checkAttemptAllowed(accountID: UUID) throws {}

    func recordFailure(accountID: UUID) throws {
        consecutiveFailuresByAccountID[accountID, default: 0] += 1
    }

    func recordSuccess(accountID: UUID) throws {
        consecutiveFailuresByAccountID[accountID] = 0
    }

    func resetLockout(accountID: UUID) throws {
        consecutiveFailuresByAccountID[accountID] = 0
    }
}
