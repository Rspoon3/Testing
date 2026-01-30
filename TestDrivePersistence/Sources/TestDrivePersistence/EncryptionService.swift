import CryptoKit
import Foundation

/// Provides cryptographic operations for vault and API key encryption.
///
/// This service handles all cryptographic primitives needed for end-to-end
/// encrypted vault sharing:
/// - X25519 key agreement for secure key exchange
/// - HKDF key derivation for wrapping keys
/// - AES-256-GCM encryption for secrets and key wrapping
public final class EncryptionService: Sendable {

    public init() {}

    // MARK: - X25519 Key Management

    /// Generates a new X25519 keypair.
    ///
    /// - Returns: A new private key. The public key can be derived from it.
    public func generateKeypair() -> Curve25519.KeyAgreement.PrivateKey {
        Curve25519.KeyAgreement.PrivateKey()
    }

    /// Exports a public key as Data.
    ///
    /// - Parameter privateKey: The private key whose public key to export.
    /// - Returns: Raw representation of the public key.
    public func publicKeyData(from privateKey: Curve25519.KeyAgreement.PrivateKey) -> Data {
        privateKey.publicKey.rawRepresentation
    }

    /// Imports a public key from Data.
    ///
    /// - Parameter data: Raw representation of the public key.
    /// - Returns: The public key.
    /// - Throws: CryptoKit error if the data is invalid.
    public func publicKey(from data: Data) throws -> Curve25519.KeyAgreement.PublicKey {
        try Curve25519.KeyAgreement.PublicKey(rawRepresentation: data)
    }

    // MARK: - Key Agreement & Wrapping

    /// Performs ECDH key agreement and derives a wrapping key via HKDF-SHA256.
    ///
    /// - Parameters:
    ///   - privateKey: The local private key.
    ///   - publicKey: The remote public key.
    ///   - salt: Salt for HKDF derivation.
    /// - Returns: A 256-bit wrapping key.
    /// - Throws: CryptoKit error if key agreement fails.
    public func deriveWrappingKey(
        privateKey: Curve25519.KeyAgreement.PrivateKey,
        publicKey: Curve25519.KeyAgreement.PublicKey,
        salt: Data
    ) throws -> SymmetricKey {
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)

        return sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: salt,
            sharedInfo: Data(),
            outputByteCount: 32
        )
    }

    /// Wraps a vault key with a wrapping key using AES-GCM.
    ///
    /// - Parameters:
    ///   - vaultKey: The vault encryption key to wrap.
    ///   - wrappingKey: The wrapping key derived from ECDH.
    /// - Returns: The ciphertext and nonce.
    /// - Throws: CryptoKit error if encryption fails.
    public func wrapVaultKey(
        _ vaultKey: SymmetricKey,
        with wrappingKey: SymmetricKey
    ) throws -> (ciphertext: Data, nonce: Data) {
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(
            keyToData(vaultKey),
            using: wrappingKey,
            nonce: nonce
        )

        return (sealedBox.ciphertext, nonce.dataRepresentation)
    }

    /// Unwraps a vault key using AES-GCM.
    ///
    /// - Parameters:
    ///   - ciphertext: The encrypted vault key.
    ///   - nonce: The nonce used for encryption.
    ///   - wrappingKey: The wrapping key derived from ECDH.
    /// - Returns: The unwrapped vault key.
    /// - Throws: CryptoKit error if decryption fails.
    public func unwrapVaultKey(
        ciphertext: Data,
        nonce: Data,
        wrappingKey: SymmetricKey
    ) throws -> SymmetricKey {
        let nonceValue = try AES.GCM.Nonce(data: nonce)
        let sealedBox = try AES.GCM.SealedBox(
            nonce: nonceValue,
            ciphertext: ciphertext,
            tag: Data()
        )

        let decryptedData = try AES.GCM.open(sealedBox, using: wrappingKey)
        return try dataToKey(decryptedData)
    }

    // MARK: - Vault Key Management

    /// Generates a random 256-bit vault key.
    ///
    /// - Returns: A new AES-256 symmetric key.
    public func generateVaultKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    /// Converts a symmetric key to Data for storage.
    ///
    /// - Parameter key: The symmetric key to convert.
    /// - Returns: Raw data representation of the key.
    public func keyToData(_ key: SymmetricKey) -> Data {
        key.withUnsafeBytes { Data($0) }
    }

    /// Converts Data to a symmetric key.
    ///
    /// - Parameter data: Raw key data.
    /// - Returns: A symmetric key.
    /// - Throws: Error if the data length is invalid.
    public func dataToKey(_ data: Data) throws -> SymmetricKey {
        guard data.count == 32 else {
            throw EncryptionError.invalidKeyLength
        }
        return SymmetricKey(data: data)
    }

    // MARK: - Secret Encryption

    /// Encrypts an API secret with a vault key using AES-256-GCM.
    ///
    /// - Parameters:
    ///   - secret: The plaintext secret to encrypt.
    ///   - vaultKey: The vault's encryption key.
    /// - Returns: The ciphertext and nonce.
    /// - Throws: CryptoKit error if encryption fails.
    public func encryptSecret(
        _ secret: String,
        with vaultKey: SymmetricKey
    ) throws -> (ciphertext: Data, nonce: Data) {
        guard let secretData = secret.data(using: .utf8) else {
            throw EncryptionError.invalidSecretEncoding
        }

        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(secretData, using: vaultKey, nonce: nonce)

        return (sealedBox.ciphertext + sealedBox.tag, nonce.dataRepresentation)
    }

    /// Decrypts an API secret using AES-256-GCM.
    ///
    /// - Parameters:
    ///   - ciphertext: The encrypted secret (includes authentication tag).
    ///   - nonce: The nonce used for encryption.
    ///   - vaultKey: The vault's encryption key.
    /// - Returns: The plaintext secret.
    /// - Throws: CryptoKit error if decryption fails.
    public func decryptSecret(
        ciphertext: Data,
        nonce: Data,
        vaultKey: SymmetricKey
    ) throws -> String {
        let nonceValue = try AES.GCM.Nonce(data: nonce)

        guard ciphertext.count >= 16 else {
            throw EncryptionError.invalidCiphertext
        }

        let tagStartIndex = ciphertext.count - 16
        let actualCiphertext = ciphertext.prefix(tagStartIndex)
        let tag = ciphertext.suffix(16)

        let sealedBox = try AES.GCM.SealedBox(
            nonce: nonceValue,
            ciphertext: actualCiphertext,
            tag: tag
        )

        let decryptedData = try AES.GCM.open(sealedBox, using: vaultKey)

        guard let secret = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidSecretEncoding
        }

        return secret
    }
}

// MARK: - Nonce Extension

extension AES.GCM.Nonce {
    /// Returns the Data representation of the nonce.
    var dataRepresentation: Data {
        withUnsafeBytes { Data($0) }
    }
}

// MARK: - Errors

/// Errors that can occur during encryption operations.
public enum EncryptionError: Error {
    /// The key data has an invalid length.
    case invalidKeyLength

    /// The secret could not be encoded as UTF-8.
    case invalidSecretEncoding

    /// The ciphertext has an invalid format.
    case invalidCiphertext

    /// The nonce has an invalid length.
    case invalidNonceLength
}
