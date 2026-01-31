# Vault Sharing Guide

This document explains TestDrive's end-to-end encrypted vault sharing system and how to test it.

## Overview

TestDrive uses **end-to-end encryption with zero-knowledge key distribution** to enable secure vault sharing. Vault encryption keys are never stored in CloudKit plaintext—only encrypted ciphertexts and cryptographically wrapped keys are synced.

## Architecture

### Key Components

1. **X25519 Keypairs** (Elliptic Curve Diffie-Hellman)
   - Owner generates keypair when creating vault
   - Private key → Device Keychain (never leaves device)
   - Public key → Vault record in CloudKit

2. **Vault Encryption Key** (AES-256)
   - Generated when vault created
   - Stored in device Keychain
   - Never stored in CloudKit plaintext

3. **Key Wrapping** (ECDH + HKDF + AES-GCM)
   - Owner wraps vault key for each recipient
   - Uses recipient's public key + ephemeral private key
   - Derives wrapping key via key agreement
   - Stores wrapped key in CloudKit

## Sharing Flow

### Step 1: Owner Shares Vault

**Owner Actions:**
1. Swipe left on vault → Tap "Share"
2. ShareVaultView appears
3. Tap "Share Vault" button
4. System share sheet (UICloudSharingController) appears
5. Enter recipient email/phone
6. Tap "Send"

**What Happens:**
```
Owner Device:
├─ Create CKShare record
├─ Link Vault record to CKShare
├─ Update vault.isShared = true
├─ Update vault.ckShareID
└─ CloudKit sends invitation to recipient
```

**CloudKit Records Created:**
- `CKShare` - Defines who has access
- `Vault` record linked to share
- `VaultParticipant` record for recipient (status: pending)

### Step 2: Recipient Accepts Share

**Recipient Actions:**
1. Receive notification (email/Messages/etc.)
2. Tap invitation link
3. Opens in TestDrive app
4. Accepts share

**What Happens:**
```
Recipient Device:
├─ Generate/Load X25519 keypair
│  ├─ Private key → Keychain
│  └─ Public key → VaultParticipant record
├─ Update participant.acceptanceStatus = accepted
├─ Update participant.publicKey = [recipient public key]
└─ Sync to CloudKit
```

**Recipient's X25519 Keypair:**
- Identifier: `recipient-{vaultID}`
- Private key stored: Device Keychain
- Public key stored: VaultParticipant.publicKey in CloudKit

### Step 3: Owner Wraps Vault Key

**Automatic Process (Background):**
1. Owner's app observes VaultParticipant changes
2. Detects new participant with public key
3. Automatically wraps vault key for recipient

**Key Wrapping Process:**
```swift
// 1. Generate ephemeral keypair (one-time use)
let ephemeralPrivate = encryption.generateKeypair()
let ephemeralPublic = encryption.publicKeyData(from: ephemeralPrivate)

// 2. Get recipient's public key
let recipientPublic = participant.publicKey

// 3. Perform ECDH key agreement
let sharedSecret = ephemeralPrivate.sharedSecret(with: recipientPublic)

// 4. Derive wrapping key via HKDF-SHA256
let wrappingKey = HKDF.deriveKey(
    from: sharedSecret,
    salt: vaultID.data,
    outputByteCount: 32
)

// 5. Encrypt vault key with wrapping key
let (ciphertext, nonce) = AES.GCM.seal(vaultKey, using: wrappingKey)

// 6. Create WrappedVaultKey record
let wrappedKey = WrappedVaultKey(
    vaultID: vault.id,
    recipientUserID: participant.userID,
    encryptedVaultKey: ciphertext + nonce,
    ephemeralPublicKey: ephemeralPublic
)

// 7. Upload to CloudKit
await database.save(wrappedKey)
```

**CloudKit Record Created:**
- `WrappedVaultKey` with encrypted vault key

### Step 4: Recipient Unwraps Vault Key

**Automatic Process (On Sync):**
1. Recipient's app syncs from CloudKit
2. Detects new WrappedVaultKey record
3. Automatically unwraps vault key

**Key Unwrapping Process:**
```swift
// 1. Load recipient's private key from Keychain
let recipientPrivate = keychain.getPrivateKey("recipient-\(vaultID)")

// 2. Get ephemeral public key from record
let ephemeralPublic = wrappedKey.ephemeralPublicKey

// 3. Perform ECDH key agreement (same shared secret!)
let sharedSecret = recipientPrivate.sharedSecret(with: ephemeralPublic)

// 4. Derive unwrapping key via HKDF-SHA256
let unwrappingKey = HKDF.deriveKey(
    from: sharedSecret,
    salt: vaultID.data,
    outputByteCount: 32
)

// 5. Decrypt vault key
let vaultKey = AES.GCM.open(
    ciphertext: wrappedKey.encryptedVaultKey,
    using: unwrappingKey
)

// 6. Cache in Keychain
keychain.cacheVaultKey(vaultKey, for: vaultID)
```

### Step 5: Recipient Accesses Keys

**Recipient Actions:**
1. Navigate to shared vault
2. View API keys
3. Tap to reveal secret

**Decryption:**
```swift
// 1. Get vault key from Keychain
let vaultKey = keychain.getCachedVaultKey(for: vaultID)

// 2. Decrypt API secret
let secret = AES.GCM.open(
    key.encryptedSecret,
    using: vaultKey
)

// 3. Display to user
```

**Result:** Recipient can decrypt and view all secrets in vault!

## Security Model

### What's Encrypted

1. **API Key Secrets** (AES-256-GCM)
   - Ciphertext: `Credential.encryptedSecret`
   - Nonce: `Credential.nonce`
   - Key: Vault AES key (in Keychain)

2. **Vault Keys** (Wrapped with derived keys)
   - Ciphertext: `WrappedVaultKey.encryptedVaultKey`
   - Key: Derived from ECDH key agreement
   - Ephemeral public key: `WrappedVaultKey.ephemeralPublicKey`

### What's Plaintext (Searchable Metadata)

- Vault name, icon, color
- API key label, domain, company
- Environment, tags, timestamps, notes
- Participant user IDs

### Security Properties

✓ **End-to-end encryption:** Only key holders can decrypt
✓ **Zero-knowledge:** CloudKit never sees vault keys
✓ **Forward secrecy:** Ephemeral keys for each wrapping
✓ **No password exchange:** Automatic cryptographic key agreement
✓ **Revocation:** Delete WrappedVaultKey → recipient loses access
✓ **Searchable metadata:** Labels/domains unencrypted for queries

### Threat Model

**Protected Against:**
- CloudKit server compromise (no plaintext keys)
- Network interception (TLS + encrypted payloads)
- Unauthorized recipients (only wrapped for invited users)
- Passive monitoring (forward secrecy via ephemeral keys)

**Not Protected Against:**
- Device compromise (vault keys in Keychain)
- Malicious participant (authorized users can decrypt)
- Physical device access (if unlocked)

## Testing Scenarios

### Scenario 1: Basic Sharing

**Prerequisites:**
- Two devices (Device A, Device B)
- Different iCloud accounts (Account A, Account B)
- Both devices have TestDrive installed

**Steps:**
1. **Device A (Owner):**
   - Create vault "Shared Test Vault"
   - Add API key "Test Key" with secret "secret123"
   - Swipe left on vault → Tap "Share"
   - Tap "Share Vault"
   - Enter Account B email
   - Tap "Send"

2. **Device B (Recipient):**
   - Receive invitation notification
   - Tap to accept
   - Opens TestDrive app
   - Pull to refresh
   - Verify "Shared Test Vault" appears

3. **Device B (Recipient):**
   - Open "Shared Test Vault"
   - See "Test Key" listed
   - Tap "Test Key" → Reveal secret
   - **Verify:** Secret shows "secret123"

**Success Criteria:**
- ✓ Recipient receives invitation
- ✓ Vault appears on recipient device
- ✓ Keys visible in vault
- ✓ Secrets decrypt correctly
- ✓ Process takes < 2 minutes

### Scenario 2: Multiple Recipients

**Steps:**
1. **Device A:** Share vault with Account B and Account C
2. **Device B & C:** Accept invitations
3. **All devices:** Verify vault access
4. **Device A:** Add new key "Multi Key"
5. **Device B & C:** Pull to refresh
6. **Verify:** "Multi Key" appears on all devices

**Success Criteria:**
- ✓ All recipients can decrypt
- ✓ New keys sync to all devices
- ✓ No conflicts or errors

### Scenario 3: Permission Management

**Steps:**
1. **Device A:** Share vault with Account B (Read & Write)
2. **Device B:** Accept, add new key "Recipient Key"
3. **Device A:** Verify "Recipient Key" appears
4. **Device A:** Change Account B to "Read Only"
5. **Device B:** Try to add key
6. **Verify:** Error or disabled (SQLiteData handles permissions)

**Success Criteria:**
- ✓ Read & Write allows creating keys
- ✓ Permission change syncs
- ✓ Read Only prevents modifications

### Scenario 4: Share Revocation

**Steps:**
1. **Device A:** Share vault with Account B
2. **Device B:** Accept, verify access
3. **Device A:** Open share settings
4. **Device A:** Remove Account B
5. **Device B:** Pull to refresh
6. **Verify:** Vault disappears from Device B

**Success Criteria:**
- ✓ Vault removed from recipient
- ✓ Recipient can't decrypt anymore
- ✓ WrappedVaultKey deleted

### Scenario 5: Offline Acceptance

**Steps:**
1. **Device A:** Share vault (online)
2. **Device B:** Enable Airplane Mode
3. **Device B:** Accept invitation (queued)
4. **Device B:** Disable Airplane Mode
5. **Wait 30 seconds**
6. **Device B:** Pull to refresh
7. **Verify:** Vault appears with accessible keys

**Success Criteria:**
- ✓ Acceptance queued while offline
- ✓ Syncs when back online
- ✓ Key wrapping happens automatically

### Scenario 6: Owner Adds Key After Sharing

**Steps:**
1. **Device A:** Create and share vault
2. **Device B:** Accept share
3. **Device A:** Add 10 new keys
4. **Device B:** Pull to refresh
5. **Verify:** All 10 keys appear and decrypt

**Success Criteria:**
- ✓ New keys sync to recipients
- ✓ Recipients can decrypt all keys
- ✓ No re-wrapping needed

## Participant Management

### Viewing Participants

1. Swipe left on vault → Tap "Share"
2. See participant list with statuses:
   - **Pending** (orange) - Invitation sent, not accepted
   - **Active** (green) - Accepted, can access vault
   - **Declined** (red) - Invitation declined

### Status Indicators

- **Checkmark seal** (green) - Public key received, vault key wrapped
- **Permission label** - Owner, Read & Write, Read Only
- **Menu (chevron)** - Change permissions or remove

### Updating Permissions

1. Open vault share settings
2. Tap permission label (e.g., "Read & Write")
3. Select new permission
4. Changes sync immediately

### Removing Participants

1. Open vault share settings
2. Tap permission menu
3. Select "Remove"
4. Confirm
5. Participant's WrappedVaultKey deleted
6. Participant loses access on next sync

### Stop Sharing

1. Open vault share settings
2. Scroll to bottom
3. Tap "Stop Sharing" (red)
4. Confirm warning
5. All participants removed
6. Vault becomes private again

## Troubleshooting

### Issue: Recipient Can't Decrypt Keys

**Symptoms:** "Failed to decrypt" error on recipient device

**Possible Causes:**
1. Wrapped key not yet synced
2. Recipient's keypair missing
3. Corruption during key wrapping

**Steps to Resolve:**
1. Device B: Pull to refresh
2. Device A: Check ShareVaultView → Participant has green checkmark
3. Device B: Force quit app, relaunch
4. Device A: Remove and re-add participant
5. Last resort: Stop sharing, reshare

### Issue: Invitation Not Received

**Symptoms:** Recipient doesn't get notification

**Possible Causes:**
1. Wrong email/phone
2. iCloud notifications disabled
3. Network delay

**Steps to Resolve:**
1. Check email/phone is correct
2. Settings → Notifications → iCloud
3. Wait up to 5 minutes
4. Resend invitation

### Issue: Vault Key Wrapping Failed

**Symptoms:** Participant shown but no checkmark seal

**Possible Causes:**
1. Participant hasn't accepted yet
2. Public key not synced
3. Owner device offline during wrapping

**Steps to Resolve:**
1. Wait for participant to accept
2. Pull to refresh on owner device
3. Check ShareVaultView → Monitor status
4. Automatic retry on next sync

### Issue: Duplicate Wrapped Keys

**Symptoms:** Multiple WrappedVaultKey records for same participant

**Cause:** Race condition during simultaneous wrapping

**Resolution:** SQLiteData deduplicates automatically; use most recent

## Performance

### Expected Times

- **Share creation:** < 5 seconds
- **Invitation delivery:** < 1 minute
- **Acceptance sync:** < 30 seconds
- **Key wrapping:** < 10 seconds
- **Key unwrapping:** < 5 seconds
- **First key decryption:** < 2 seconds

### Network Usage

- **Share creation:** ~5 KB
- **Per participant:** ~2 KB
- **Wrapped key:** ~1 KB
- **Public key:** ~32 bytes

## CloudKit Records

### CKShare (System Record)

Created by CloudKit, links participants to shared Vault.

**Fields:**
- `participants` - Array of CKShareParticipant
- `owner` - CKShareParticipant (creator)
- `publicPermission` - CKShareParticipantPermission

### Vault (App Record)

**Sharing-Related Fields:**
- `isShared: Bool` - Whether vault is shared
- `ckShareID: String?` - Reference to CKShare
- `ownerUserID: String?` - CloudKit user ID of owner
- `ownerPublicKey: Data` - X25519 public key for wrapping

### VaultParticipant (App Record)

**Fields:**
- `vaultID: UUID` - Which vault
- `userID: String` - CKUserIdentity record name
- `publicKey: Data?` - Recipient's X25519 public key
- `permission: SharePermission` - Access level
- `acceptanceStatus: AcceptanceStatus` - Invitation status
- `addedAt: Date` - When added

### WrappedVaultKey (App Record)

**Fields:**
- `vaultID: UUID` - Which vault
- `recipientUserID: String` - Who it's for
- `encryptedVaultKey: Data` - Wrapped vault key (ciphertext + nonce)
- `ephemeralPublicKey: Data` - For unwrapping (32 bytes)
- `wrappedAt: Date` - When wrapped

## Best Practices

### For Owners

1. **Share responsibly** - Only with trusted users
2. **Review participants regularly** - Remove inactive users
3. **Use appropriate permissions** - Read Only when possible
4. **Monitor for suspicious activity** - Unusual key access patterns
5. **Rotate keys periodically** - Even for shared vaults

### For Recipients

1. **Accept promptly** - Don't delay acceptance
2. **Verify vault source** - Ensure from trusted owner
3. **Don't share credentials** - Each person gets own access
4. **Report issues immediately** - Contact owner if problems
5. **Respect permissions** - Honor Read Only restrictions

### Security Recommendations

1. **Device security** - Use strong passcode/biometrics
2. **iCloud security** - Enable two-factor authentication
3. **Regular audits** - Review shared vaults monthly
4. **Revoke when done** - Remove access when no longer needed
5. **Separate vaults** - Don't mix personal/work in shared vaults

## Next Steps

After implementing sharing:
1. Test all scenarios above
2. Verify encryption at each step
3. Monitor CloudKit Dashboard
4. Gather user feedback
5. Optimize performance
6. Add audit logging (Phase 7+)
