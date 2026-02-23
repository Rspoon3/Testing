# Architecture

## Summary

The implementation follows a nesting-doll key hierarchy:

1. Secret ciphertext is encrypted by a credential key.
2. Credential key is wrapped by a vault key.
3. Vault key is wrapped by ARK.
4. ARK is wrapped by one or more account-level wrappers:
   - recovery wrapper
   - device wrapper
   - optional sync wrapper

This preserves a zero-knowledge data model for persisted records.

## Pyramid diagram

```text
                 DeviceWrapKey / RecoveryWrapKey / SyncWrapKey
                                   (outer wraps)
                                            │
                                           ARK
                                            │ wraps
                                       Vault Key
                                            │ wraps
                                    Credential Key (DEK)
                                            │ encrypts
                                     Secret Ciphertext
```

## Implementation mapping

- Tables and persisted encrypted blobs:
  - ``AccountRootWrapRow``
  - ``DeviceEnrollmentRow``
  - ``Vault``
  - ``Credential``
  - ``Secret``
- Symmetric AEAD/key wrapping:
  - ``EnvelopeCrypto``
- ARK lifecycle and wrappers:
  - ``AccountKeyCoordinator``
- Account metadata persistence:
  - ``AccountMetadataStore``
- Keychain-backed wrap-key storage:
  - ``KeychainWrapKeyStore``
- Biometric `SecAccessControl` policy wiring for device keys:
  - ``KeychainWrapKeyStore/DeviceAccessPolicy``
- SQLite persistence and decrypt path:
  - ``EnvelopeStore``

## Persisted data model

The sample persists only opaque encrypted values and metadata:

- `Vault.wrappedVaultKeyByARK`
- `Credential.wrappedCredentialKeyByVaultKey`
- `Secret.ciphertext`

It does not persist plaintext keys or plaintext secrets.

## Production notes

In a real app, keep this architecture and swap in platform services:

- Store `DeviceWrapKey` in Secure Enclave/Keychain.
- Persist account wraps (`wrappedARKByRecovery`, optional `wrappedARKBySync`) in trusted storage.
- Use CloudKit metadata and server authorization for sharing and enrollment workflows.
