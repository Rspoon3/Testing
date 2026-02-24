import CryptoKit
import Foundation
import LocalAuthentication
import Security

/// Keychain-backed storage for local wrap keys.
///
    /// On devices with a Secure Enclave, the 256-bit device wrap key is encrypted
    /// (ECIES) using a hardware-bound P-256 private key. On environments without
    /// Secure Enclave, falls back to raw Keychain storage.
enum KeychainWrapKeyStore {
    /// Authentication behavior used when loading/creating a device wrap key.
    struct DeviceAccessPolicy {
        /// Required authentication primitive for key access.
        enum Requirement {
            /// Require the currently enrolled biometric set.
            case biometryCurrentSet
            /// Require user presence (biometric or passcode).
            case userPresence
        }

        /// Access-control requirement.
        var requirement: Requirement
        /// Prompt shown by Keychain when authentication UI is needed.
        var operationPrompt: String
        /// Optional caller-provided LAContext.
        var authenticationContext: LAContext?

        /// Biometric-only default policy for device wrap keys.
        static func biometricDefault(
            prompt: String = "Authenticate to unlock your device wrap key."
        ) -> DeviceAccessPolicy {
            DeviceAccessPolicy(
                requirement: .biometryCurrentSet,
                operationPrompt: prompt,
                authenticationContext: nil
            )
        }
    }

    enum StoreError: Error {
        case unexpectedStatus(OSStatus)
        case invalidStoredData
        case accessControlCreationFailed
        case secureEnclaveKeyCreationFailed
        case encryptionFailed
        case decryptionFailed
        case publicKeyCopyFailed
    }

    private static let service = "com.testdrive.envelope.wrap-keys"
    private static let seService = "com.testdrive.envelope.se-keys"

    // MARK: - Public API

    /// Loads or creates a device wrap key for one account/device pair.
    ///
    /// On Secure Enclave-capable hardware the wrap key is encrypted with an
    /// SE-bound P-256 key. On environments without Secure Enclave this uses
    /// raw Keychain storage.
    static func loadOrCreateDeviceWrapKey(
        accountID: UUID,
        deviceID: UUID,
        policy: DeviceAccessPolicy = .biometricDefault()
    ) throws -> SymmetricKey {
        let account = "device|\(accountID.uuidString)|\(deviceID.uuidString)"

        if SecureEnclave.isAvailable {
            return try loadOrCreateDeviceWrapKeySE(account: account, policy: policy)
        } else {
            return try loadOrCreateDeviceWrapKeyFallback(account: account, policy: policy)
        }
    }

    /// Loads or creates an optional sync wrap key for one account.
    static func loadOrCreateSyncWrapKey(accountID: UUID) throws -> SymmetricKey {
        try loadOrCreate(account: "sync|\(accountID.uuidString)")
    }

    // MARK: - Secure Enclave Path

    /// Loads or creates a device wrap key protected by a Secure Enclave P-256 key.
    private static func loadOrCreateDeviceWrapKeySE(
        account: String,
        policy: DeviceAccessPolicy
    ) throws -> SymmetricKey {
        let sePrivateKey = try loadOrCreateSEPrivateKey(account: account, policy: policy)

        if let encryptedBlob = try loadEncryptedBlob(account: account) {
            return try decryptWithSEPrivateKey(encryptedBlob, privateKey: sePrivateKey)
        }

        let key = SymmetricKey(size: .bits256)
        guard let publicKey = SecKeyCopyPublicKey(sePrivateKey) else {
            throw StoreError.publicKeyCopyFailed
        }
        let encryptedBlob = try encryptWithSEPublicKey(key, publicKey: publicKey)
        try saveEncryptedBlob(encryptedBlob, account: account)
        return key
    }

    /// Queries or creates a Secure Enclave P-256 private key with biometric access control.
    private static func loadOrCreateSEPrivateKey(
        account: String,
        policy: DeviceAccessPolicy
    ) throws -> SecKey {
        let tag = "com.testdrive.envelope.se.\(account)"
        let tagData = Data(tag.utf8)

        // Try to load existing key
        let loadQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrApplicationTag as String: tagData,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecReturnRef as String: true,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(loadQuery as CFDictionary, &result)
        if status == errSecSuccess, let key = result {
            // swiftlint:disable:next force_cast
            return key as! SecKey
        }

        // Create new SE key
        let flags: SecAccessControlCreateFlags = {
            switch policy.requirement {
            case .biometryCurrentSet:
                return [.privateKeyUsage, .biometryCurrentSet]
            case .userPresence:
                return [.privateKeyUsage, .userPresence]
            }
        }()

        var accessControlError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            flags,
            &accessControlError
        ) else {
            _ = accessControlError?.takeRetainedValue()
            throw StoreError.accessControlCreationFailed
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tagData,
                kSecAttrAccessControl as String: accessControl,
            ],
        ]

        var creationError: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &creationError) else {
            _ = creationError?.takeRetainedValue()
            throw StoreError.secureEnclaveKeyCreationFailed
        }

        return privateKey
    }

    /// Encrypts a symmetric key using the Secure Enclave public key via ECIES.
    private static func encryptWithSEPublicKey(
        _ key: SymmetricKey,
        publicKey: SecKey
    ) throws -> Data {
        try key.withUnsafeBytes { rawBytes -> Data in
            var plaintext = Data(rawBytes)
            defer { plaintext.resetBytes(in: 0..<plaintext.count) }
            var error: Unmanaged<CFError>?
            guard let ciphertext = SecKeyCreateEncryptedData(
                publicKey,
                .eciesEncryptionCofactorVariableIVX963SHA256AESGCM,
                plaintext as CFData,
                &error
            ) else {
                _ = error?.takeRetainedValue()
                throw StoreError.encryptionFailed
            }
            return ciphertext as Data
        }
    }

    /// Decrypts an ECIES blob using the Secure Enclave private key.
    private static func decryptWithSEPrivateKey(
        _ ciphertext: Data,
        privateKey: SecKey
    ) throws -> SymmetricKey {
        var error: Unmanaged<CFError>?
        guard let plaintext = SecKeyCreateDecryptedData(
            privateKey,
            .eciesEncryptionCofactorVariableIVX963SHA256AESGCM,
            ciphertext as CFData,
            &error
        ) else {
            _ = error?.takeRetainedValue()
            throw StoreError.decryptionFailed
        }
        return SymmetricKey(data: plaintext as Data)
    }

    /// Loads an ECIES-encrypted wrap key blob from Keychain.
    private static func loadEncryptedBlob(account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: seService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw StoreError.unexpectedStatus(status)
        }
    }

    /// Saves an ECIES-encrypted wrap key blob to Keychain.
    private static func saveEncryptedBlob(_ blob: Data, account: String) throws {
        let item: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: seService,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            kSecValueData as String: blob,
        ]

        let addStatus = SecItemAdd(item as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return
        }
        if addStatus == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: seService,
                kSecAttrAccount as String: account,
            ]
            let updateAttributes: [String: Any] = [
                kSecValueData as String: blob,
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw StoreError.unexpectedStatus(updateStatus)
            }
            return
        }

        throw StoreError.unexpectedStatus(addStatus)
    }

    // MARK: - Fallback Path

    /// Loads or creates a device wrap key using raw Keychain storage (no Secure Enclave).
    private static func loadOrCreateDeviceWrapKeyFallback(
        account: String,
        policy: DeviceAccessPolicy
    ) throws -> SymmetricKey {
        if let existing = try loadDeviceKeyFallback(account: account, policy: policy) {
            return existing
        }

        let key = SymmetricKey(size: .bits256)
        try saveDeviceKeyFallback(key: key, account: account, policy: policy)
        return key
    }

    private static func loadDeviceKeyFallback(
        account: String,
        policy: DeviceAccessPolicy
    ) throws -> SymmetricKey? {
        let authenticationContext: LAContext = {
            if let context = policy.authenticationContext {
                return context
            }
            return LAContext()
        }()
        authenticationContext.localizedReason = policy.operationPrompt
        authenticationContext.interactionNotAllowed = false

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: authenticationContext,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard
                let data = result as? Data,
                data.count == 32
            else {
                throw StoreError.invalidStoredData
            }
            return SymmetricKey(data: data)
        case errSecItemNotFound:
            return nil
        default:
            throw StoreError.unexpectedStatus(status)
        }
    }

    private static func saveDeviceKeyFallback(
        key: SymmetricKey,
        account: String,
        policy: DeviceAccessPolicy
    ) throws {
        var error: Unmanaged<CFError>?
        let flags: SecAccessControlCreateFlags = {
            switch policy.requirement {
            case .biometryCurrentSet:
                return [.biometryCurrentSet]
            case .userPresence:
                return [.userPresence]
            }
        }()
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            flags,
            &error
        ) else {
            _ = error?.takeRetainedValue()
            throw StoreError.accessControlCreationFailed
        }

        try key.withUnsafeBytes { rawBytes in
            var data = Data(rawBytes)
            defer { data.resetBytes(in: 0..<data.count) }
            let item: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrAccessControl as String: accessControl,
                kSecValueData as String: data,
            ]

            let addStatus = SecItemAdd(item as CFDictionary, nil)
            if addStatus == errSecSuccess {
                return
            }
            if addStatus == errSecDuplicateItem {
                let deleteQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                    kSecAttrAccount as String: account,
                ]
                let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
                guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
                    throw StoreError.unexpectedStatus(deleteStatus)
                }

                let retryStatus = SecItemAdd(item as CFDictionary, nil)
                guard retryStatus == errSecSuccess else {
                    throw StoreError.unexpectedStatus(retryStatus)
                }
                return
            }

            throw StoreError.unexpectedStatus(addStatus)
        }
    }

    // MARK: - Sync Key Helpers

    private static func loadOrCreate(account: String) throws -> SymmetricKey {
        if let existing = try load(account: account) {
            return existing
        }

        let key = SymmetricKey(size: .bits256)
        try save(
            key: key,
            account: account,
            accessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        )
        return key
    }

    private static func load(account: String) throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard
                let data = result as? Data,
                data.count == 32
            else {
                throw StoreError.invalidStoredData
            }
            return SymmetricKey(data: data)
        case errSecItemNotFound:
            return nil
        default:
            throw StoreError.unexpectedStatus(status)
        }
    }

    private static func save(
        key: SymmetricKey,
        account: String,
        accessible: CFString
    ) throws {
        try key.withUnsafeBytes { rawBytes in
            var data = Data(rawBytes)
            defer { data.resetBytes(in: 0..<data.count) }
            let item: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrAccessible as String: accessible,
                kSecValueData as String: data,
            ]

            let addStatus = SecItemAdd(item as CFDictionary, nil)
            if addStatus == errSecSuccess {
                return
            }
            if addStatus == errSecDuplicateItem {
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                    kSecAttrAccount as String: account,
                ]
                let update: [String: Any] = [
                    kSecValueData as String: data
                ]
                let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
                guard updateStatus == errSecSuccess else {
                    throw StoreError.unexpectedStatus(updateStatus)
                }
                return
            }

            throw StoreError.unexpectedStatus(addStatus)
        }
    }
}
