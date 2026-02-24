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

/// DB-agnostic persistence port used by the envelope domain layer.
protocol EnvelopeDomainPersisting {
    func upsertVault(_ vault: PersistedVault) throws
    func loadVault(id: UUID) throws -> PersistedVault
    func fetchVault(id: UUID) throws -> PersistedVault?

    func upsertCredential(_ credential: PersistedCredential) throws
    func loadCredential(id: UUID) throws -> PersistedCredential
    func fetchCredential(id: UUID) throws -> PersistedCredential?
    func loadCredentials(vaultID: UUID) throws -> [PersistedCredential]

    func upsertSecretField(_ field: PersistedSecretField) throws
    func loadSecretField(id: UUID) throws -> PersistedSecretField
    func loadSecretFields(itemID: UUID) throws -> [PersistedSecretField]
}
