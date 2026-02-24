import CryptoKit
import Foundation

/// Low-level crypto helpers for envelope encryption.
///
/// This sample uses AES-GCM for both payload encryption and key wrapping.
enum EnvelopeCrypto {
    /// Errors emitted by envelope crypto operations.
    enum CryptoError: Error {
        /// Returned when CryptoKit cannot provide the combined sealed-box representation.
        case missingCombinedRepresentation
        /// Returned when a ciphertext/wrap references an unsupported crypto version.
        case unsupportedCryptoVersion(Int)
    }

    /// Encrypts raw bytes with AEAD and returns the AES-GCM combined representation.
    ///
    /// - Parameters:
    ///   - plaintext: Bytes to encrypt.
    ///   - key: Symmetric encryption key.
    ///   - aad: Associated authenticated data that binds context to the ciphertext.
    /// - Returns: Combined AES-GCM bytes (`nonce || ciphertext || tag`).
    static func seal(_ plaintext: Data, using key: SymmetricKey, aad: Data) throws -> Data {
        try seal(plaintext, using: key, aad: aad, cryptoVersion: 1)
    }

    /// Encrypts raw bytes with an explicit crypto-version dispatch.
    static func seal(
        _ plaintext: Data,
        using key: SymmetricKey,
        aad: Data,
        cryptoVersion: Int
    ) throws -> Data {
        switch cryptoVersion {
        case 1:
            return try sealV1(plaintext, using: key, aad: aad)
        default:
            throw CryptoError.unsupportedCryptoVersion(cryptoVersion)
        }
    }

    private static func sealV1(_ plaintext: Data, using key: SymmetricKey, aad: Data) throws -> Data {
        let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: aad)
        guard let combined = sealed.combined else {
            throw CryptoError.missingCombinedRepresentation
        }
        return combined
    }

    /// Decrypts AES-GCM combined bytes.
    ///
    /// - Parameters:
    ///   - combined: Combined AES-GCM bytes.
    ///   - key: Symmetric decryption key.
    ///   - aad: Associated authenticated data used during encryption.
    static func open(_ combined: Data, using key: SymmetricKey, aad: Data) throws -> Data {
        try open(combined, using: key, aad: aad, cryptoVersion: 1)
    }

    /// Decrypts AES-GCM combined bytes with explicit crypto-version dispatch.
    static func open(
        _ combined: Data,
        using key: SymmetricKey,
        aad: Data,
        cryptoVersion: Int
    ) throws -> Data {
        switch cryptoVersion {
        case 1:
            return try openV1(combined, using: key, aad: aad)
        default:
            throw CryptoError.unsupportedCryptoVersion(cryptoVersion)
        }
    }

    private static func openV1(_ combined: Data, using key: SymmetricKey, aad: Data) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: combined)
        return try AES.GCM.open(box, using: key, authenticating: aad)
    }

    /// Wraps an inner symmetric key using a wrapping key.
    ///
    /// The wrapped output is AEAD-protected bytes that can be persisted.
    static func wrapKey(_ innerKey: SymmetricKey, wrappingKey: SymmetricKey, aad: Data) throws -> Data {
        try wrapKey(innerKey, wrappingKey: wrappingKey, aad: aad, cryptoVersion: 1)
    }

    /// Wraps an inner symmetric key with explicit crypto-version dispatch.
    static func wrapKey(
        _ innerKey: SymmetricKey,
        wrappingKey: SymmetricKey,
        aad: Data,
        cryptoVersion: Int
    ) throws -> Data {
        try seal(
            innerKey.withUnsafeBytes { Data($0) },
            using: wrappingKey,
            aad: aad,
            cryptoVersion: cryptoVersion
        )
    }

    /// Unwraps a previously wrapped symmetric key.
    static func unwrapKey(_ wrappedKey: Data, wrappingKey: SymmetricKey, aad: Data) throws -> SymmetricKey {
        try unwrapKey(wrappedKey, wrappingKey: wrappingKey, aad: aad, cryptoVersion: 1)
    }

    /// Unwraps a previously wrapped symmetric key with explicit crypto-version dispatch.
    static func unwrapKey(
        _ wrappedKey: Data,
        wrappingKey: SymmetricKey,
        aad: Data,
        cryptoVersion: Int
    ) throws -> SymmetricKey {
        let keyData = try open(wrappedKey, using: wrappingKey, aad: aad, cryptoVersion: cryptoVersion)
        return SymmetricKey(data: keyData)
    }
}

/// Deterministic key identifiers persisted alongside wrapped/encrypted blobs.
enum EnvelopeKeyID {
    static let cryptoVersion = 1
    static let aadVersion = 1
    static let implicitAccountARK = "ark:account:implicit"

    static func accountARK(accountID: UUID) -> String {
        "ark:account:\(accountID.uuidString)"
    }

    static func recoveryWrapKey(accountID: UUID) -> String {
        "wrap:recovery:\(accountID.uuidString)"
    }

    static func syncWrapKey(accountID: UUID) -> String {
        "wrap:sync:\(accountID.uuidString)"
    }

    static func deviceWrapKey(accountID: UUID, deviceID: UUID) -> String {
        "wrap:device:\(accountID.uuidString):\(deviceID.uuidString)"
    }

    static func vaultKey(vaultID: UUID) -> String {
        "key:vault:\(vaultID.uuidString)"
    }

    static func itemKey(itemID: UUID) -> String {
        "key:item:\(itemID.uuidString)"
    }
}

/// Deterministic AAD namespaces used by the envelope stack.
///
/// AAD prevents ciphertext/key-swapping across contexts.
enum EnvelopeAAD {
    /// AAD for a vault key wrapped by ARK.
    static func vaultKey(vaultID: UUID) -> Data {
        Data("vault:\(vaultID.uuidString)|vaultKey|v1".utf8)
    }

    /// AAD for an item key wrapped by its vault key.
    static func itemKey(vaultID: UUID, itemID: UUID) -> Data {
        Data("vault:\(vaultID.uuidString)|item:\(itemID.uuidString)|key|v1".utf8)
    }

    /// AAD for a generic item field encrypted by an item key.
    static func itemField(
        itemID: UUID,
        fieldID: UUID,
        cryptoVersion: Int,
        aadVersion: Int
    ) -> Data {
        Data(
            "item:\(itemID.uuidString)|fieldID:\(fieldID.uuidString)|crypto:\(cryptoVersion)|aad:\(aadVersion)"
                .utf8
        )
    }

    /// AAD for an encrypted credential file payload.
    static func itemFile(
        itemID: UUID,
        fileID: UUID,
        cryptoVersion: Int,
        aadVersion: Int
    ) -> Data {
        Data(
            "item:\(itemID.uuidString)|fileID:\(fileID.uuidString)|crypto:\(cryptoVersion)|aad:\(aadVersion)"
                .utf8
        )
    }
}
