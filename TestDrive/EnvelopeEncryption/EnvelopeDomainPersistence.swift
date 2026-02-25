import Dependencies
import Foundation

/// Persisted vault metadata and ARK-wrapped vault key.
struct PersistedVault: Identifiable, Sendable {
    let id: UUID
    var name: String
    var keyID: String
    var wrappedByKeyID: String
    var cryptoVersion: Int
    var aadVersion: Int
    var wrappedVaultKeyByARK: Data
}

/// Persisted credential metadata and vault-wrapped item key.
struct PersistedCredential: Identifiable, Sendable {
    let id: UUID
    var vaultID: UUID
    var title: String
    var type: VaultItemType
    var payloadVersion: Int
    var keyID: String
    var wrappedByKeyID: String
    var cryptoVersion: Int
    var aadVersion: Int
    var wrappedItemKeyByVaultKey: Data
    var createdAt: Date
    var updatedAt: Date
}

/// Persisted encrypted secret field payload.
struct PersistedSecretField: Identifiable, Sendable {
    let id: UUID
    var itemID: UUID
    var fieldName: String
    var keyID: String
    var wrappedByKeyID: String
    var cryptoVersion: Int
    var aadVersion: Int
    var ciphertext: Data
    var createdAt: Date
    var updatedAt: Date
}

/// DB-agnostic persistence client used by the envelope domain layer.
struct EnvelopeDomainPersistenceClient: Sendable {
    var upsertVault: @Sendable (_ vault: PersistedVault) throws -> Void
    var loadVault: @Sendable (_ id: UUID) throws -> PersistedVault
    var fetchVault: @Sendable (_ id: UUID) throws -> PersistedVault?

    var upsertCredential: @Sendable (_ credential: PersistedCredential) throws -> Void
    var upsertCredentialWithInitialSecret:
        @Sendable (_ credential: PersistedCredential, _ initialSecretField: PersistedSecretField) throws -> Void
    var loadCredential: @Sendable (_ id: UUID) throws -> PersistedCredential
    var fetchCredential: @Sendable (_ id: UUID) throws -> PersistedCredential?
    var loadCredentials: @Sendable (_ vaultID: UUID) throws -> [PersistedCredential]

    var upsertSecretField: @Sendable (_ field: PersistedSecretField) throws -> Void
    var loadSecretField: @Sendable (_ id: UUID) throws -> PersistedSecretField
    var loadSecretFields: @Sendable (_ itemID: UUID) throws -> [PersistedSecretField]
}

extension EnvelopeDomainPersistenceClient: DependencyKey {
    static var liveValue: EnvelopeDomainPersistenceClient {
        .unimplemented
    }

    static var testValue: EnvelopeDomainPersistenceClient {
        .unimplemented
    }
}

extension DependencyValues {
    var envelopeDomainPersistence: EnvelopeDomainPersistenceClient {
        get { self[EnvelopeDomainPersistenceClient.self] }
        set { self[EnvelopeDomainPersistenceClient.self] = newValue }
    }
}

extension EnvelopeDomainPersistenceClient {
    static var unimplemented: EnvelopeDomainPersistenceClient {
        EnvelopeDomainPersistenceClient(
            upsertVault: { _ in
                throw DependencyNotConfiguredError(endpoint: "envelopeDomainPersistence.upsertVault")
            },
            loadVault: { _ in
                throw DependencyNotConfiguredError(endpoint: "envelopeDomainPersistence.loadVault")
            },
            fetchVault: { _ in
                throw DependencyNotConfiguredError(endpoint: "envelopeDomainPersistence.fetchVault")
            },
            upsertCredential: { _ in
                throw DependencyNotConfiguredError(endpoint: "envelopeDomainPersistence.upsertCredential")
            },
            upsertCredentialWithInitialSecret: { _, _ in
                throw DependencyNotConfiguredError(
                    endpoint: "envelopeDomainPersistence.upsertCredentialWithInitialSecret"
                )
            },
            loadCredential: { _ in
                throw DependencyNotConfiguredError(endpoint: "envelopeDomainPersistence.loadCredential")
            },
            fetchCredential: { _ in
                throw DependencyNotConfiguredError(endpoint: "envelopeDomainPersistence.fetchCredential")
            },
            loadCredentials: { _ in
                throw DependencyNotConfiguredError(endpoint: "envelopeDomainPersistence.loadCredentials")
            },
            upsertSecretField: { _ in
                throw DependencyNotConfiguredError(endpoint: "envelopeDomainPersistence.upsertSecretField")
            },
            loadSecretField: { _ in
                throw DependencyNotConfiguredError(endpoint: "envelopeDomainPersistence.loadSecretField")
            },
            loadSecretFields: { _ in
                throw DependencyNotConfiguredError(endpoint: "envelopeDomainPersistence.loadSecretFields")
            }
        )
    }
}
