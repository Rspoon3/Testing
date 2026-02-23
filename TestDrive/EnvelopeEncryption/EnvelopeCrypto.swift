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
    }

    /// Encrypts raw bytes with AEAD and returns the AES-GCM combined representation.
    ///
    /// - Parameters:
    ///   - plaintext: Bytes to encrypt.
    ///   - key: Symmetric encryption key.
    ///   - aad: Associated authenticated data that binds context to the ciphertext.
    /// - Returns: Combined AES-GCM bytes (`nonce || ciphertext || tag`).
    static func seal(_ plaintext: Data, using key: SymmetricKey, aad: Data) throws -> Data {
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
        let box = try AES.GCM.SealedBox(combined: combined)
        return try AES.GCM.open(box, using: key, authenticating: aad)
    }

    /// Wraps an inner symmetric key using a wrapping key.
    ///
    /// The wrapped output is AEAD-protected bytes that can be persisted.
    static func wrapKey(_ innerKey: SymmetricKey, wrappingKey: SymmetricKey, aad: Data) throws -> Data {
        try seal(innerKey.withUnsafeBytes { Data($0) }, using: wrappingKey, aad: aad)
    }

    /// Unwraps a previously wrapped symmetric key.
    static func unwrapKey(_ wrappedKey: Data, wrappingKey: SymmetricKey, aad: Data) throws -> SymmetricKey {
        let keyData = try open(wrappedKey, using: wrappingKey, aad: aad)
        return SymmetricKey(data: keyData)
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

    /// AAD for a credential key wrapped by its vault key.
    static func credentialKey(vaultID: UUID, credentialID: UUID) -> Data {
        Data("vault:\(vaultID.uuidString)|credential:\(credentialID.uuidString)|key|v1".utf8)
    }

    /// AAD for a secret payload encrypted by a credential key.
    static func secret(credentialID: UUID, secretName: String) -> Data {
        Data("credential:\(credentialID.uuidString)|secret:\(secretName)|v1".utf8)
    }
}
