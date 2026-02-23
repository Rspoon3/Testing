import CryptoKit
import Foundation

/// Persistable account-level ARK wrappers.
///
/// In a production app this metadata can live in a secure server record and/or local persistence.
struct AccountRootWraps {
    /// Logical account identifier that scopes all root wraps.
    let accountID: UUID
    /// Salt used when deriving the recovery wrap key from recovery code.
    var recoverySalt: Data
    /// Identifier of the wrapped ARK key material.
    var arkKeyID: String
    /// Identifier of the recovery-derived key used to wrap ARK.
    var recoveryWrappedByKeyID: String
    /// Ciphertext format/algorithm version for the recovery wrap.
    var recoveryCryptoVersion: Int
    /// ARK wrapped by recovery-derived key.
    var wrappedARKByRecovery: Data
    /// Identifier of the sync key used to wrap ARK.
    var syncWrappedByKeyID: String?
    /// Ciphertext format/algorithm version for the sync wrap.
    var syncCryptoVersion: Int?
    /// Optional ARK wrapped by sync key (for iCloud Keychain convenience path).
    var wrappedARKBySync: Data?
}

/// One device's local ARK enrollment record.
struct DeviceEnrollment {
    /// Logical account identifier.
    let accountID: UUID
    /// Device identifier for this enrollment.
    let deviceID: UUID
    /// Identifier of the wrapped ARK key material.
    let arkKeyID: String
    /// Identifier of the device wrap key used for wrapping.
    let wrappedByKeyID: String
    /// Ciphertext format/algorithm version.
    let cryptoVersion: Int
    /// ARK wrapped for this specific device's local wrap key.
    let wrappedARKByDevice: Data
}

/// Result produced when creating a brand new account root.
struct AccountBootstrapResult {
    /// Account root key generated for the account.
    let ark: SymmetricKey
    /// Account-level persisted wraps.
    let rootWraps: AccountRootWraps
    /// First trusted device enrollment.
    let initialDevice: DeviceEnrollment
}

/// Derives a recovery wrap key from a human-entered recovery code.
///
/// This sample uses HKDF-SHA256 from CryptoKit as a practical iOS-native derivation.
enum RecoveryWrapKeyDeriver {
    private static let info = Data("devcreds.recovery-wrap-key.v1".utf8)

    /// Generates a random salt for recovery key derivation.
    static func makeSalt(byteCount: Int = 32) -> Data {
        Data((0..<byteCount).map { _ in UInt8.random(in: .min ... .max) })
    }

    /// Derives a 256-bit recovery wrap key from recovery code and salt.
    static func derive(recoveryCode: String, salt: Data) -> SymmetricKey {
        let inputMaterial = SymmetricKey(data: Data(recoveryCode.utf8))
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputMaterial,
            salt: salt,
            info: info,
            outputByteCount: 32
        )
    }
}

/// AAD namespaces for ARK wrapping variants.
enum AccountRootAAD {
    /// AAD for recovery-wrapped ARK.
    static func arkByRecovery(accountID: UUID) -> Data {
        Data("account:\(accountID.uuidString)|ark|recovery|v1".utf8)
    }

    /// AAD for per-device ARK wrapping.
    static func arkByDevice(accountID: UUID, deviceID: UUID) -> Data {
        Data("account:\(accountID.uuidString)|ark|device:\(deviceID.uuidString)|v1".utf8)
    }

    /// AAD for sync-key wrapped ARK.
    static func arkBySync(accountID: UUID) -> Data {
        Data("account:\(accountID.uuidString)|ark|sync|v1".utf8)
    }
}

/// Coordinates ARK lifecycle operations:
/// account bootstrap, recovery unlock, sync unlock, and device enrollment.
enum AccountKeyCoordinator {
    /// Errors produced by account root coordination.
    enum Error: Swift.Error {
        /// Requested sync unlock but no sync-wrapped ARK exists.
        case missingSyncWrap
    }

    /// Creates a new account root and all initial wraps.
    ///
    /// - Parameters:
    ///   - accountID: Stable account identifier.
    ///   - recoveryCode: User-owned recovery material.
    ///   - initialDeviceID: First trusted device identifier.
    ///   - initialDeviceWrapKey: Device-local wrap key (Secure Enclave/Keychain in production).
    ///   - metadataStore: Persistence adapter for root wraps and device enrollments.
    ///   - syncWrapKey: Optional convenience key for iCloud Keychain style bootstrap.
    /// - Returns: ARK plus persisted wrap metadata and first device enrollment.
    static func bootstrapAccount(
        accountID: UUID,
        recoveryCode: String,
        initialDeviceID: UUID,
        initialDeviceWrapKey: SymmetricKey,
        metadataStore: AccountMetadataStore,
        syncWrapKey: SymmetricKey? = nil
    ) throws -> AccountBootstrapResult {
        let ark = SymmetricKey(size: .bits256)
        let arkKeyID = EnvelopeKeyID.accountARK(accountID: accountID)
        let recoveryWrappedByKeyID = EnvelopeKeyID.recoveryWrapKey(accountID: accountID)
        let syncWrappedByKeyID = syncWrapKey.map { _ in
            EnvelopeKeyID.syncWrapKey(accountID: accountID)
        }

        let recoverySalt = RecoveryWrapKeyDeriver.makeSalt()
        let recoveryWrapKey = RecoveryWrapKeyDeriver.derive(
            recoveryCode: recoveryCode,
            salt: recoverySalt
        )
        let wrappedARKByRecovery = try EnvelopeCrypto.wrapKey(
            ark,
            wrappingKey: recoveryWrapKey,
            aad: AccountRootAAD.arkByRecovery(accountID: accountID)
        )

        let wrappedARKBySync = try syncWrapKey.map {
            try EnvelopeCrypto.wrapKey(
                ark,
                wrappingKey: $0,
                aad: AccountRootAAD.arkBySync(accountID: accountID)
            )
        }

        let rootWraps = AccountRootWraps(
            accountID: accountID,
            recoverySalt: recoverySalt,
            arkKeyID: arkKeyID,
            recoveryWrappedByKeyID: recoveryWrappedByKeyID,
            recoveryCryptoVersion: EnvelopeKeyID.cryptoVersion,
            wrappedARKByRecovery: wrappedARKByRecovery,
            syncWrappedByKeyID: syncWrappedByKeyID,
            syncCryptoVersion: wrappedARKBySync == nil ? nil : EnvelopeKeyID.cryptoVersion,
            wrappedARKBySync: wrappedARKBySync
        )

        let initialDevice = try enrollDeviceWithoutPersistence(
            accountID: accountID,
            ark: ark,
            deviceID: initialDeviceID,
            deviceWrapKey: initialDeviceWrapKey
        )
        try metadataStore.saveRootWraps(rootWraps)
        try metadataStore.saveDeviceEnrollment(initialDevice)

        return AccountBootstrapResult(ark: ark, rootWraps: rootWraps, initialDevice: initialDevice)
    }

    /// Recovers ARK from recovery code using persisted account metadata.
    static func recoverARK(
        metadataStore: AccountMetadataStore,
        accountID: UUID,
        recoveryCode: String
    ) throws -> SymmetricKey {
        let rootWraps = try metadataStore.loadRootWraps(accountID: accountID)
        return try recoverARK(rootWraps: rootWraps, recoveryCode: recoveryCode)
    }

    /// Recovers ARK from recovery code.
    static func recoverARK(rootWraps: AccountRootWraps, recoveryCode: String) throws -> SymmetricKey {
        let recoveryWrapKey = RecoveryWrapKeyDeriver.derive(
            recoveryCode: recoveryCode,
            salt: rootWraps.recoverySalt
        )
        return try EnvelopeCrypto.unwrapKey(
            rootWraps.wrappedARKByRecovery,
            wrappingKey: recoveryWrapKey,
            aad: AccountRootAAD.arkByRecovery(accountID: rootWraps.accountID)
        )
    }

    /// Unlocks ARK using optional sync-wrap path from persisted account metadata.
    static func unlockARKFromSync(
        metadataStore: AccountMetadataStore,
        accountID: UUID,
        syncWrapKey: SymmetricKey
    ) throws -> SymmetricKey {
        let rootWraps = try metadataStore.loadRootWraps(accountID: accountID)
        return try unlockARKFromSync(rootWraps: rootWraps, syncWrapKey: syncWrapKey)
    }

    /// Unlocks ARK using optional sync-wrap path.
    static func unlockARKFromSync(rootWraps: AccountRootWraps, syncWrapKey: SymmetricKey) throws -> SymmetricKey {
        guard let wrappedARKBySync = rootWraps.wrappedARKBySync else {
            throw Error.missingSyncWrap
        }
        return try EnvelopeCrypto.unwrapKey(
            wrappedARKBySync,
            wrappingKey: syncWrapKey,
            aad: AccountRootAAD.arkBySync(accountID: rootWraps.accountID)
        )
    }

    /// Creates and persists a per-device ARK wrap for a new trusted device.
    static func enrollDevice(
        metadataStore: AccountMetadataStore,
        accountID: UUID,
        ark: SymmetricKey,
        deviceID: UUID,
        deviceWrapKey: SymmetricKey
    ) throws -> DeviceEnrollment {
        let enrollment = try enrollDeviceWithoutPersistence(
            accountID: accountID,
            ark: ark,
            deviceID: deviceID,
            deviceWrapKey: deviceWrapKey
        )
        try metadataStore.saveDeviceEnrollment(enrollment)
        return enrollment
    }

    /// Creates a per-device ARK wrap for a new trusted device.
    static func enrollDevice(
        accountID: UUID,
        ark: SymmetricKey,
        deviceID: UUID,
        deviceWrapKey: SymmetricKey
    ) throws -> DeviceEnrollment {
        try enrollDeviceWithoutPersistence(
            accountID: accountID,
            ark: ark,
            deviceID: deviceID,
            deviceWrapKey: deviceWrapKey
        )
    }

    private static func enrollDeviceWithoutPersistence(
        accountID: UUID,
        ark: SymmetricKey,
        deviceID: UUID,
        deviceWrapKey: SymmetricKey
    ) throws -> DeviceEnrollment {
        let wrappedARKByDevice = try EnvelopeCrypto.wrapKey(
            ark,
            wrappingKey: deviceWrapKey,
            aad: AccountRootAAD.arkByDevice(accountID: accountID, deviceID: deviceID)
        )
        return DeviceEnrollment(
            accountID: accountID,
            deviceID: deviceID,
            arkKeyID: EnvelopeKeyID.accountARK(accountID: accountID),
            wrappedByKeyID: EnvelopeKeyID.deviceWrapKey(accountID: accountID, deviceID: deviceID),
            cryptoVersion: EnvelopeKeyID.cryptoVersion,
            wrappedARKByDevice: wrappedARKByDevice
        )
    }

    /// Unlocks ARK for a persisted device enrollment.
    static func unlockARKForDevice(
        metadataStore: AccountMetadataStore,
        accountID: UUID,
        deviceID: UUID,
        deviceWrapKey: SymmetricKey
    ) throws -> SymmetricKey {
        let enrollment = try metadataStore.loadDeviceEnrollment(accountID: accountID, deviceID: deviceID)
        return try unlockARKForDevice(enrollment: enrollment, deviceWrapKey: deviceWrapKey)
    }

    /// Unlocks ARK for a specific enrolled device.
    static func unlockARKForDevice(
        enrollment: DeviceEnrollment,
        deviceWrapKey: SymmetricKey
    ) throws -> SymmetricKey {
        try EnvelopeCrypto.unwrapKey(
            enrollment.wrappedARKByDevice,
            wrappingKey: deviceWrapKey,
            aad: AccountRootAAD.arkByDevice(accountID: enrollment.accountID, deviceID: enrollment.deviceID)
        )
    }
}
