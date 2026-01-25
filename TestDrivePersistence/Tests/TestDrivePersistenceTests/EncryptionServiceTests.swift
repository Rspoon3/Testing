import CryptoKit
import Foundation
import Testing
@testable import TestDrivePersistence

/// Tests for the EncryptionService.
@Suite struct EncryptionServiceTests {

    let service = EncryptionService()

    // MARK: - Key Generation Tests

    @Test func generateKeypair() async throws {
        let privateKey = service.generateKeypair()
        let publicKeyData = service.publicKeyData(from: privateKey)

        #expect(publicKeyData.count == 32)
    }

    @Test func generateVaultKey() async throws {
        let vaultKey = service.generateVaultKey()
        let vaultKeyData = service.keyToData(vaultKey)

        #expect(vaultKeyData.count == 32)
    }

    // MARK: - Key Conversion Tests

    @Test func keyToDataConversion() async throws {
        let key = SymmetricKey(size: .bits256)
        let data = service.keyToData(key)

        #expect(data.count == 32)
    }

    @Test func dataToKeyConversion() async throws {
        let originalKey = SymmetricKey(size: .bits256)
        let data = service.keyToData(originalKey)
        let reconstructedKey = try service.dataToKey(data)
        let reconstructedData = service.keyToData(reconstructedKey)

        #expect(data == reconstructedData)
    }

    @Test func dataToKeyInvalidLength() async throws {
        let invalidData = Data(repeating: 0, count: 16)

        #expect(throws: EncryptionError.self) {
            try service.dataToKey(invalidData)
        }
    }

    // MARK: - Secret Encryption Tests

    @Test func encryptAndDecryptSecret() async throws {
        let vaultKey = service.generateVaultKey()
        let secret = "sk-test-1234567890abcdef"

        let (ciphertext, nonce) = try service.encryptSecret(secret, with: vaultKey)
        let decrypted = try service.decryptSecret(
            ciphertext: ciphertext,
            nonce: nonce,
            vaultKey: vaultKey
        )

        #expect(decrypted == secret)
        #expect(ciphertext != secret.data(using: .utf8)!)
    }

    @Test func encryptedSecretsAreDifferent() async throws {
        let vaultKey = service.generateVaultKey()
        let secret = "sk-test-1234567890abcdef"

        let (ciphertext1, _) = try service.encryptSecret(secret, with: vaultKey)
        let (ciphertext2, _) = try service.encryptSecret(secret, with: vaultKey)

        #expect(ciphertext1 != ciphertext2)
    }

    @Test func decryptWithWrongKey() async throws {
        let vaultKey1 = service.generateVaultKey()
        let vaultKey2 = service.generateVaultKey()
        let secret = "sk-test-1234567890abcdef"

        let (ciphertext, nonce) = try service.encryptSecret(secret, with: vaultKey1)

        #expect(throws: CryptoKitError.self) {
            try service.decryptSecret(ciphertext: ciphertext, nonce: nonce, vaultKey: vaultKey2)
        }
    }

    // MARK: - Key Agreement Tests

    @Test func deriveWrappingKey() async throws {
        let alicePrivate = service.generateKeypair()
        let bobPrivate = service.generateKeypair()

        let bobPublicData = service.publicKeyData(from: bobPrivate)
        let bobPublic = try service.publicKey(from: bobPublicData)

        let salt = Data(repeating: 0, count: 32)
        let wrappingKey = try service.deriveWrappingKey(
            privateKey: alicePrivate,
            publicKey: bobPublic,
            salt: salt
        )

        let wrappingKeyData = service.keyToData(wrappingKey)
        #expect(wrappingKeyData.count == 32)
    }

    @Test func ecdhKeyAgreement() async throws {
        let alicePrivate = service.generateKeypair()
        let bobPrivate = service.generateKeypair()

        let alicePublic = try service.publicKey(from: service.publicKeyData(from: alicePrivate))
        let bobPublic = try service.publicKey(from: service.publicKeyData(from: bobPrivate))

        let salt = Data(repeating: 1, count: 32)

        let aliceKey = try service.deriveWrappingKey(
            privateKey: alicePrivate,
            publicKey: bobPublic,
            salt: salt
        )

        let bobKey = try service.deriveWrappingKey(
            privateKey: bobPrivate,
            publicKey: alicePublic,
            salt: salt
        )

        #expect(service.keyToData(aliceKey) == service.keyToData(bobKey))
    }

    // MARK: - Vault Key Wrapping Tests

    @Test func wrapAndUnwrapVaultKey() async throws {
        let vaultKey = service.generateVaultKey()
        let wrappingKey = service.generateVaultKey()

        let (ciphertext, nonce) = try service.wrapVaultKey(vaultKey, with: wrappingKey)
        let unwrappedKey = try service.unwrapVaultKey(
            ciphertext: ciphertext,
            nonce: nonce,
            wrappingKey: wrappingKey
        )

        #expect(service.keyToData(vaultKey) == service.keyToData(unwrappedKey))
    }

    @Test func unwrapWithWrongKey() async throws {
        let vaultKey = service.generateVaultKey()
        let wrappingKey1 = service.generateVaultKey()
        let wrappingKey2 = service.generateVaultKey()

        let (ciphertext, nonce) = try service.wrapVaultKey(vaultKey, with: wrappingKey1)

        #expect(throws: CryptoKitError.self) {
            try service.unwrapVaultKey(ciphertext: ciphertext, nonce: nonce, wrappingKey: wrappingKey2)
        }
    }

    // MARK: - End-to-End Key Wrapping Flow

    @Test func endToEndKeyWrapping() async throws {
        let ownerPrivate = service.generateKeypair()
        let recipientPrivate = service.generateKeypair()

        let vaultKey = service.generateVaultKey()

        let ephemeralPrivate = service.generateKeypair()
        let recipientPublic = try service.publicKey(
            from: service.publicKeyData(from: recipientPrivate)
        )

        let salt = Data(repeating: 2, count: 32)
        let wrappingKey = try service.deriveWrappingKey(
            privateKey: ephemeralPrivate,
            publicKey: recipientPublic,
            salt: salt
        )

        let (wrappedKey, nonce) = try service.wrapVaultKey(vaultKey, with: wrappingKey)

        let ephemeralPublic = try service.publicKey(
            from: service.publicKeyData(from: ephemeralPrivate)
        )

        let recipientWrappingKey = try service.deriveWrappingKey(
            privateKey: recipientPrivate,
            publicKey: ephemeralPublic,
            salt: salt
        )

        let unwrappedKey = try service.unwrapVaultKey(
            ciphertext: wrappedKey,
            nonce: nonce,
            wrappingKey: recipientWrappingKey
        )

        #expect(service.keyToData(vaultKey) == service.keyToData(unwrappedKey))
    }
}
