# Envelope Encryption Reference

This DocC catalog documents the minimal, production-oriented envelope encryption sample used in `TestDrive`.

The sample demonstrates a layered key model:

- `DeviceWrapKey` (device-local)
- `RecoveryWrapKey` / optional `SyncWrapKey` (account bootstrap paths)
- `ARK` (account root key)
- Vault key (KEK)
- Credential key (item key / DEK)
- Secret ciphertext

## Why this sample exists

This project intentionally focuses on architecture and key flows without binding to full CloudKit sharing or Secure Enclave APIs.

You can use this as a drop-in reference when implementing real key storage and sync infrastructure.

This sample uses persistent storage for all key-wrap metadata:

- SQLite file-backed metadata and ciphertext persistence.
- Keychain-backed device and sync wrap-key storage.
- Biometric-gated `SecAccessControl` policy for device wrap-key access.

## Topics

### Architecture

- <doc:Architecture>
- <doc:KeyLifecycleFlows>
- <doc:SharedVaultPolicy>

### Core Symbols

- ``EnvelopeStore``
- ``AccountKeyCoordinator``
- ``AccountMetadataStore``
- ``KeychainWrapKeyStore``
- ``EnvelopePaths``
- ``EnvelopeCrypto``
- ``Vault``
- ``Credential``
- ``Secret``
- ``EnvelopeEncryptionDemo``
