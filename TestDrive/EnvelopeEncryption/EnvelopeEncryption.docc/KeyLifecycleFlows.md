# Key Lifecycle Flows

## Account bootstrap

Handled by ``AccountKeyCoordinator/bootstrapAccount(accountID:recoveryCode:initialDeviceID:initialDeviceWrapKey:metadataStore:syncWrapKey:)``:

1. Generate a new ARK.
2. Derive `RecoveryWrapKey` from recovery code and salt.
3. Wrap ARK for recovery (`wrappedARKByRecovery`).
4. Optionally wrap ARK for sync (`wrappedARKBySync`).
5. Enroll the first device by wrapping ARK with device-local wrap key.
6. Persist wraps and enrollment using ``AccountMetadataStore``.

## Device unlock

Handled by ``AccountKeyCoordinator/unlockARKForDevice(metadataStore:accountID:deviceID:deviceWrapKey:)``:

1. Load `DeviceEnrollment` record.
2. Load device wrap key from Keychain with biometric `SecAccessControl`.
3. Unwrap ARK using that device's wrap key.
4. Instantiate ``EnvelopeStore`` with unlocked ARK.

The Keychain policy is configured by ``KeychainWrapKeyStore/DeviceAccessPolicy`` and uses `kSecAttrAccessControl`.

## Recovery unlock

Handled by ``AccountKeyCoordinator/recoverARK(metadataStore:accountID:recoveryCode:)``:

1. Re-derive `RecoveryWrapKey` from user recovery code.
2. Unwrap ARK from `wrappedARKByRecovery`.
3. Optionally enroll a new device.

## Sync unlock (optional)

Handled by ``AccountKeyCoordinator/unlockARKFromSync(metadataStore:accountID:syncWrapKey:)``:

1. Retrieve sync wrap key from synchronizable secure storage.
2. Unwrap ARK from `wrappedARKBySync`.

## Secret write/read path

Write path (`EnvelopeStore`):

1. Unwrap vault key from `Vault.wrappedVaultKeyByARK`.
2. Unwrap credential key from `Credential.wrappedCredentialKeyByVaultKey`.
3. Encrypt plaintext secret and insert `Secret.ciphertext`.

Read path (`EnvelopeStore`):

1. Load secret row.
2. Re-unwrap vault and credential keys.
3. Decrypt ciphertext to reveal plaintext in-memory.
