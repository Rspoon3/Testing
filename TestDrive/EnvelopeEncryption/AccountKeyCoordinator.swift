import CryptoKit
import CommonCrypto
import Dependencies
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
    /// Associated-data format version for the recovery wrap.
    var recoveryAADVersion: Int
    /// ARK wrapped by recovery-derived key.
    var wrappedARKByRecovery: Data
    /// Identifier of the sync key used to wrap ARK.
    var syncWrappedByKeyID: String?
    /// Ciphertext format/algorithm version for the sync wrap.
    var syncCryptoVersion: Int?
    /// Associated-data format version for the sync wrap.
    var syncAADVersion: Int?
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
    /// Associated-data format version.
    let aadVersion: Int
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
/// Uses PBKDF2-HMAC-SHA256 to make offline brute-force guessing expensive.
enum RecoveryWrapKeyDeriver {
    enum Error: Swift.Error {
        case keyDerivationFailed(status: Int32)
    }

    private static let keyLength = 32
    private static let iterations: UInt32 = 300_000

    /// Generates a cryptographically secure random salt for recovery key derivation.
    static func makeSalt(byteCount: Int = 32) -> Data {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        precondition(status == errSecSuccess, "SecRandomCopyBytes failed with status \(status)")
        return Data(bytes)
    }

    /// Derives a 256-bit recovery wrap key from recovery code and salt.
    static func derive(recoveryCode: String, salt: Data) throws -> SymmetricKey {
        let passwordData = Data(recoveryCode.utf8)
        var derivedKey = Data(repeating: 0, count: keyLength)

        let status = derivedKey.withUnsafeMutableBytes { derivedBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.bindMemory(to: Int8.self).baseAddress,
                        passwordData.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        iterations,
                        derivedBytes.bindMemory(to: UInt8.self).baseAddress,
                        keyLength
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw Error.keyDerivationFailed(status: status)
        }

        return SymmetricKey(data: derivedKey)
    }
}

/// AAD namespaces for ARK wrapping variants.
enum AccountRootAAD {
    /// AAD for recovery-wrapped ARK.
    static func arkByRecovery(accountID: UUID, aadVersion: Int) -> Data {
        Data("account:\(accountID.uuidString)|ark|recovery|aad:\(aadVersion)".utf8)
    }

    /// AAD for per-device ARK wrapping.
    static func arkByDevice(accountID: UUID, deviceID: UUID, aadVersion: Int) -> Data {
        Data("account:\(accountID.uuidString)|ark|device:\(deviceID.uuidString)|aad:\(aadVersion)".utf8)
    }

    /// AAD for sync-key wrapped ARK.
    static func arkBySync(accountID: UUID, aadVersion: Int) -> Data {
        Data("account:\(accountID.uuidString)|ark|sync|aad:\(aadVersion)".utf8)
    }
}

/// Coordinates ARK lifecycle operations:
/// account bootstrap, recovery unlock, sync unlock, and device enrollment.
enum AccountKeyCoordinator {
    /// Errors produced by account root coordination.
    enum Error: Swift.Error {
        /// Requested sync unlock but no sync-wrapped ARK exists.
        case missingSyncWrap
        /// Sync wrap exists but required version metadata is missing.
        case invalidSyncWrapMetadata
    }

    /// Creates a new account root and all initial wraps.
    ///
    /// - Parameters:
    ///   - accountID: Stable account identifier.
    ///   - recoveryCode: User-owned recovery material.
    ///   - initialDeviceID: First trusted device identifier.
    ///   - initialDeviceWrapKey: Device-local wrap key (Secure Enclave/Keychain in production).
    ///   - syncWrapKey: Optional convenience key for iCloud Keychain style bootstrap.
    /// - Returns: ARK plus persisted wrap metadata and first device enrollment.
    static func bootstrapAccount(
        accountID: UUID,
        recoveryCode: String,
        initialDeviceID: UUID,
        initialDeviceWrapKey: SymmetricKey,
        syncWrapKey: SymmetricKey? = nil
    ) throws -> AccountBootstrapResult {
        @Dependency(\.accountMetadata) var accountMetadata
        @Dependency(\.recoveryWrapKeyDeriver) var recoveryWrapKeyDeriver
        let ark = SymmetricKey(size: .bits256)
        let arkKeyID = EnvelopeKeyID.accountARK(accountID: accountID)
        let recoveryWrappedByKeyID = EnvelopeKeyID.recoveryWrapKey(accountID: accountID)
        let syncWrappedByKeyID = syncWrapKey.map { _ in
            EnvelopeKeyID.syncWrapKey(accountID: accountID)
        }

        let recoverySalt = recoveryWrapKeyDeriver.makeSalt(32)
        let recoveryWrapKey = try recoveryWrapKeyDeriver.derive(recoveryCode, recoverySalt)
        let wrappedARKByRecovery = try EnvelopeCrypto.wrapKey(
            ark,
            wrappingKey: recoveryWrapKey,
            aad: AccountRootAAD.arkByRecovery(accountID: accountID, aadVersion: EnvelopeKeyID.aadVersion),
            cryptoVersion: EnvelopeKeyID.cryptoVersion
        )

        let wrappedARKBySync = try syncWrapKey.map {
            try EnvelopeCrypto.wrapKey(
                ark,
                wrappingKey: $0,
                aad: AccountRootAAD.arkBySync(accountID: accountID, aadVersion: EnvelopeKeyID.aadVersion),
                cryptoVersion: EnvelopeKeyID.cryptoVersion
            )
        }

        let rootWraps = AccountRootWraps(
            accountID: accountID,
            recoverySalt: recoverySalt,
            arkKeyID: arkKeyID,
            recoveryWrappedByKeyID: recoveryWrappedByKeyID,
            recoveryCryptoVersion: EnvelopeKeyID.cryptoVersion,
            recoveryAADVersion: EnvelopeKeyID.aadVersion,
            wrappedARKByRecovery: wrappedARKByRecovery,
            syncWrappedByKeyID: syncWrappedByKeyID,
            syncCryptoVersion: wrappedARKBySync == nil ? nil : EnvelopeKeyID.cryptoVersion,
            syncAADVersion: wrappedARKBySync == nil ? nil : EnvelopeKeyID.aadVersion,
            wrappedARKBySync: wrappedARKBySync
        )

        let initialDevice = try enrollDeviceWithoutPersistence(
            accountID: accountID,
            ark: ark,
            deviceID: initialDeviceID,
            deviceWrapKey: initialDeviceWrapKey
        )
        try accountMetadata.saveRootWraps(rootWraps)
        try accountMetadata.saveDeviceEnrollment(initialDevice)

        return AccountBootstrapResult(ark: ark, rootWraps: rootWraps, initialDevice: initialDevice)
    }

    /// Recovers ARK from recovery code using persisted account metadata.
    ///
    /// This call always enforces exponential backoff and lockout via the
    /// provided `attemptTracker`.
    /// - Parameters:
    ///   - accountID: Account to recover.
    ///   - recoveryCode: User-entered recovery material.
    /// - Returns: The unwrapped account root key.
    static func recoverARK(
        accountID: UUID,
        recoveryCode: String
    ) throws -> SymmetricKey {
        @Dependency(\.accountMetadata) var accountMetadata
        @Dependency(\.recoveryAttemptTracker) var recoveryAttemptTracker
        try recoveryAttemptTracker.checkAttemptAllowed(accountID)

        let rootWraps = try accountMetadata.loadRootWraps(accountID)
        do {
            let ark = try recoverARK(rootWraps: rootWraps, recoveryCode: recoveryCode)
            try recoveryAttemptTracker.recordSuccess(accountID)
            return ark
        } catch {
            try? recoveryAttemptTracker.recordFailure(accountID)
            throw error
        }
    }

    /// Recovers ARK from recovery code.
    private static func recoverARK(rootWraps: AccountRootWraps, recoveryCode: String) throws -> SymmetricKey {
        @Dependency(\.recoveryWrapKeyDeriver) var recoveryWrapKeyDeriver
        let recoveryWrapKey = try recoveryWrapKeyDeriver.derive(recoveryCode, rootWraps.recoverySalt)
        return try EnvelopeCrypto.unwrapKey(
            rootWraps.wrappedARKByRecovery,
            wrappingKey: recoveryWrapKey,
            aad: AccountRootAAD.arkByRecovery(
                accountID: rootWraps.accountID,
                aadVersion: rootWraps.recoveryAADVersion
            ),
            cryptoVersion: rootWraps.recoveryCryptoVersion
        )
    }

    /// Unlocks ARK using optional sync-wrap path from persisted account metadata.
    static func unlockARKFromSync(
        accountID: UUID,
        syncWrapKey: SymmetricKey
    ) throws -> SymmetricKey {
        @Dependency(\.accountMetadata) var accountMetadata
        let rootWraps = try accountMetadata.loadRootWraps(accountID)
        return try unlockARKFromSync(rootWraps: rootWraps, syncWrapKey: syncWrapKey)
    }

    /// Unlocks ARK using optional sync-wrap path.
    static func unlockARKFromSync(rootWraps: AccountRootWraps, syncWrapKey: SymmetricKey) throws -> SymmetricKey {
        guard let wrappedARKBySync = rootWraps.wrappedARKBySync else {
            throw Error.missingSyncWrap
        }
        guard let syncCryptoVersion = rootWraps.syncCryptoVersion else {
            throw Error.invalidSyncWrapMetadata
        }
        guard let syncAADVersion = rootWraps.syncAADVersion else {
            throw Error.invalidSyncWrapMetadata
        }
        return try EnvelopeCrypto.unwrapKey(
            wrappedARKBySync,
            wrappingKey: syncWrapKey,
            aad: AccountRootAAD.arkBySync(accountID: rootWraps.accountID, aadVersion: syncAADVersion),
            cryptoVersion: syncCryptoVersion
        )
    }

    /// Creates and persists a per-device ARK wrap for a new trusted device.
    static func enrollDevice(
        accountID: UUID,
        ark: SymmetricKey,
        deviceID: UUID,
        deviceWrapKey: SymmetricKey
    ) throws -> DeviceEnrollment {
        @Dependency(\.accountMetadata) var accountMetadata
        let enrollment = try enrollDeviceWithoutPersistence(
            accountID: accountID,
            ark: ark,
            deviceID: deviceID,
            deviceWrapKey: deviceWrapKey
        )
        try accountMetadata.saveDeviceEnrollment(enrollment)
        return enrollment
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
            aad: AccountRootAAD.arkByDevice(
                accountID: accountID,
                deviceID: deviceID,
                aadVersion: EnvelopeKeyID.aadVersion
            ),
            cryptoVersion: EnvelopeKeyID.cryptoVersion
        )
        return DeviceEnrollment(
            accountID: accountID,
            deviceID: deviceID,
            arkKeyID: EnvelopeKeyID.accountARK(accountID: accountID),
            wrappedByKeyID: EnvelopeKeyID.deviceWrapKey(accountID: accountID, deviceID: deviceID),
            cryptoVersion: EnvelopeKeyID.cryptoVersion,
            aadVersion: EnvelopeKeyID.aadVersion,
            wrappedARKByDevice: wrappedARKByDevice
        )
    }

    /// Unlocks ARK for a persisted device enrollment.
    static func unlockARKForDevice(
        accountID: UUID,
        deviceID: UUID,
        deviceWrapKey: SymmetricKey
    ) throws -> SymmetricKey {
        @Dependency(\.accountMetadata) var accountMetadata
        let enrollment = try accountMetadata.loadDeviceEnrollment(accountID, deviceID)
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
            aad: AccountRootAAD.arkByDevice(
                accountID: enrollment.accountID,
                deviceID: enrollment.deviceID,
                aadVersion: enrollment.aadVersion
            ),
            cryptoVersion: enrollment.cryptoVersion
        )
    }
}
