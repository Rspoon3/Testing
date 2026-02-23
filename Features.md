# Features

## Envelope Encryption Reference Architecture
Persistent envelope encryption over SQLite with multi-device enrollment, recovery code unlock, and iCloud sync key paths. Hierarchy: ARK → Vault Key → Credential Key → Secret ciphertext.

## Secure Enclave Device Wrap Key Protection
Device wrap keys are encrypted via ECIES using a hardware-bound P-256 private key in the Secure Enclave. Falls back to raw Keychain storage on Simulator.

## SQLite File Protection
iOS file protection (`FileProtectionType.complete`) applied to the database file and its parent directory, making data inaccessible when the device is locked.

## Background Key Zeroing
In-memory ARK is nilled out when the app enters background, causing CryptoKit's `SymmetricKey` to zero its memory on deallocation. A locked screen with an unlock button is shown on foreground.
