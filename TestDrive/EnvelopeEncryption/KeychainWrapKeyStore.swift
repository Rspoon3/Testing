import CryptoKit
import Foundation
import LocalAuthentication
import Security

/// Keychain-backed storage for local wrap keys.
///
/// This sample stores 256-bit symmetric keys as ThisDeviceOnly keychain items.
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
    }

    private static let service = "com.testdrive.envelope.wrap-keys"

    /// Loads or creates a device wrap key for one account/device pair.
    ///
    /// Device keys are protected with `SecAccessControl` and authentication gates.
    static func loadOrCreateDeviceWrapKey(
        accountID: UUID,
        deviceID: UUID,
        policy: DeviceAccessPolicy = .biometricDefault()
    ) throws -> SymmetricKey {
        let account = "device|\(accountID.uuidString)|\(deviceID.uuidString)"
        if let existing = try loadDeviceKey(account: account, policy: policy) {
            return existing
        }

        let key = SymmetricKey(size: .bits256)
        try saveDeviceKey(key: key, account: account, policy: policy)
        return key
    }

    /// Loads or creates an optional sync wrap key for one account.
    static func loadOrCreateSyncWrapKey(accountID: UUID) throws -> SymmetricKey {
        try loadOrCreate(account: "sync|\(accountID.uuidString)")
    }

    private static func loadOrCreate(account: String) throws -> SymmetricKey {
        if let existing = try load(account: account) {
            return existing
        }

        let key = SymmetricKey(size: .bits256)
        try save(
            key: key,
            account: account,
            accessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        )
        return key
    }

    private static func loadDeviceKey(account: String, policy: DeviceAccessPolicy) throws -> SymmetricKey? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseOperationPrompt as String: policy.operationPrompt,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIAllow,
        ]
        if let context = policy.authenticationContext {
            query[kSecUseAuthenticationContext as String] = context
        }

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

    private static func saveDeviceKey(
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

        let data = key.withUnsafeBytes { Data($0) }
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

    private static func save(
        key: SymmetricKey,
        account: String,
        accessible: CFString
    ) throws {
        let data = key.withUnsafeBytes { Data($0) }
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
