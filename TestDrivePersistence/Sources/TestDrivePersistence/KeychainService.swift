import Foundation
import Security

/// Provides secure storage for sensitive cryptographic keys in the iOS Keychain.
///
/// This service stores:
/// - Vault encryption keys (AES-256 keys for encrypting API secrets)
/// - X25519 private keys (for ECDH key agreement)
///
/// All keys are stored with `kSecAttrAccessibleAfterFirstUnlock` for
/// background sync support while maintaining security.
public final class KeychainService: Sendable {

    private let service = "com.rspoon3.TestDrive"

    public init() {}

    // MARK: - Vault Key Storage

    /// Stores a vault encryption key in the Keychain.
    ///
    /// - Parameters:
    ///   - key: The vault key data to store.
    ///   - vaultID: The vault identifier.
    /// - Throws: KeychainError if storage fails.
    public func cacheVaultKey(_ key: Data, for vaultID: UUID) throws {
        let account = "vault-key-\(vaultID.uuidString)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            try updateVaultKey(key, for: vaultID)
        } else if status != errSecSuccess {
            throw KeychainError.storageFailed(status: status)
        }
    }

    /// Retrieves a cached vault encryption key from the Keychain.
    ///
    /// - Parameter vaultID: The vault identifier.
    /// - Returns: The vault key data, or nil if not found.
    /// - Throws: KeychainError if retrieval fails.
    public func getCachedVaultKey(for vaultID: UUID) throws -> Data? {
        let account = "vault-key-\(vaultID.uuidString)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        } else if status != errSecSuccess {
            throw KeychainError.retrievalFailed(status: status)
        }

        guard let keyData = result as? Data else {
            throw KeychainError.invalidData
        }

        return keyData
    }

    /// Updates an existing vault key in the Keychain.
    ///
    /// - Parameters:
    ///   - key: The new vault key data.
    ///   - vaultID: The vault identifier.
    /// - Throws: KeychainError if update fails.
    private func updateVaultKey(_ key: Data, for vaultID: UUID) throws {
        let account = "vault-key-\(vaultID.uuidString)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let update: [String: Any] = [
            kSecValueData as String: key
        ]

        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)

        if status != errSecSuccess {
            throw KeychainError.updateFailed(status: status)
        }
    }

    /// Deletes a cached vault key from the Keychain.
    ///
    /// - Parameter vaultID: The vault identifier.
    /// - Throws: KeychainError if deletion fails.
    public func clearCachedVaultKey(for vaultID: UUID) throws {
        let account = "vault-key-\(vaultID.uuidString)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deletionFailed(status: status)
        }
    }

    // MARK: - X25519 Private Key Storage

    /// Stores an X25519 private key in the Keychain.
    ///
    /// - Parameters:
    ///   - privateKey: The private key data to store.
    ///   - identifier: A unique identifier for the key.
    /// - Throws: KeychainError if storage fails.
    public func storePrivateKey(_ privateKey: Data, identifier: String) throws {
        let account = "x25519-private-\(identifier)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: privateKey,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            try updatePrivateKey(privateKey, identifier: identifier)
        } else if status != errSecSuccess {
            throw KeychainError.storageFailed(status: status)
        }
    }

    /// Retrieves an X25519 private key from the Keychain.
    ///
    /// - Parameter identifier: The unique identifier for the key.
    /// - Returns: The private key data, or nil if not found.
    /// - Throws: KeychainError if retrieval fails.
    public func getPrivateKey(identifier: String) throws -> Data? {
        let account = "x25519-private-\(identifier)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        } else if status != errSecSuccess {
            throw KeychainError.retrievalFailed(status: status)
        }

        guard let keyData = result as? Data else {
            throw KeychainError.invalidData
        }

        return keyData
    }

    /// Updates an existing private key in the Keychain.
    ///
    /// - Parameters:
    ///   - privateKey: The new private key data.
    ///   - identifier: The unique identifier for the key.
    /// - Throws: KeychainError if update fails.
    private func updatePrivateKey(_ privateKey: Data, identifier: String) throws {
        let account = "x25519-private-\(identifier)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let update: [String: Any] = [
            kSecValueData as String: privateKey
        ]

        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)

        if status != errSecSuccess {
            throw KeychainError.updateFailed(status: status)
        }
    }

    /// Deletes a private key from the Keychain.
    ///
    /// - Parameter identifier: The unique identifier for the key.
    /// - Throws: KeychainError if deletion fails.
    public func deletePrivateKey(identifier: String) throws {
        let account = "x25519-private-\(identifier)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deletionFailed(status: status)
        }
    }

    // MARK: - Bulk Operations

    /// Deletes all cached vault keys from the Keychain.
    ///
    /// - Throws: KeychainError if deletion fails.
    public func clearAllCachedKeys() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deletionFailed(status: status)
        }
    }
}

// MARK: - Errors

/// Errors that can occur during Keychain operations.
public enum KeychainError: Error {
    /// Failed to store an item in the Keychain.
    case storageFailed(status: OSStatus)

    /// Failed to retrieve an item from the Keychain.
    case retrievalFailed(status: OSStatus)

    /// Failed to update an item in the Keychain.
    case updateFailed(status: OSStatus)

    /// Failed to delete an item from the Keychain.
    case deletionFailed(status: OSStatus)

    /// The retrieved data is invalid or corrupted.
    case invalidData
}
