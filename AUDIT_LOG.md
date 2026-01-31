# Audit Log System Design

## Overview

This document describes the comprehensive audit log system for the credential manager application. The system tracks all create, edit, delete, copy, and reveal actions across vaults, credentials, and secrets, providing complete visibility into "who did what and when" for compliance and security monitoring.

## Table of Contents

- [Why Audit Logging?](#why-audit-logging)
- [Architecture](#architecture)
- [Data Model](#data-model)
- [Services](#services)
- [Integration Points](#integration-points)
- [User Interface](#user-interface)
- [CloudKit Sync](#cloudkit-sync)
- [Performance](#performance)
- [Privacy & Security](#privacy--security)
- [Implementation Roadmap](#implementation-roadmap)

---

## Why Audit Logging?

### Business Requirements

- **Compliance**: Meet regulatory requirements for access tracking and audit trails
- **Security**: Monitor for suspicious activity patterns (excessive copying, unauthorized access)
- **Accountability**: Attribute all actions to specific users in shared vaults
- **Transparency**: Build user trust by providing complete visibility into vault activity
- **Debugging**: Diagnose issues by understanding the sequence of actions

### Why a Separate Audit Log Table?

We chose a dedicated `auditLogs` table over adding audit fields to existing tables because:

#### ✅ Complete History
- **Audit table**: Stores EVERY action with unlimited history
- **Audit fields**: Only stores "last modified by" (loses all previous history)
- **Example**: "John copied secret 5x → Mary rotated → John copied again" vs. "Last modified: John"

#### ✅ Track Non-Modifying Actions
- **Reveal**: When someone views a secret (doesn't modify the record)
- **Copy**: When someone copies to clipboard (changes `copyCount`, but we want WHO copied)
- Audit fields on existing tables can't track these because the entity itself doesn't change meaningfully

#### ✅ Preserve Deleted Entity Audit Trail
- When you delete a credential, the audit log preserves "John deleted AWS Prod at 3:45pm"
- With audit fields: `DELETE FROM credentials` removes all audit data forever

#### ✅ Unified Activity Timeline
```sql
-- Audit log (simple):
SELECT * FROM auditLogs WHERE vaultID = ? AND timestamp > ?

-- Audit fields (complex and incomplete):
SELECT 'vault', modifiedBy, modifiedAt FROM vaults WHERE id = ?
UNION ALL
SELECT 'credential', modifiedBy, modifiedAt FROM credentials WHERE vaultID = ?
-- Still missing: deleted items, copy/reveal actions, rotation history
```

#### ✅ Rich Metadata
- Store action-specific details in JSON: "Copy #3", "Rotation reason: compromised"
- Audit fields: Where would you store metadata for the 3rd historical rotation?

#### ✅ No Schema Pollution
- Don't need `createdBy`, `createdAt`, `modifiedBy`, `modifiedAt` on EVERY table
- Changes: 0 existing tables modified vs. 4+ tables modified

#### ✅ Retention Policy
```sql
-- Easy cleanup:
DELETE FROM auditLogs WHERE timestamp < DATE('now', '-90 days')

-- Audit fields: Can't delete old audit data without deleting the entity
```

---

## Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                        │
├─────────────────────────────────────────────────────────────┤
│  VaultManager  │  CredentialManager  │  ViewModels          │
└────────┬────────────────┬─────────────────────┬─────────────┘
         │                │                     │
         └────────────────┴─────────────────────┘
                          │
                    ┌─────▼─────┐
                    │ AuditLogger│
                    └─────┬─────┘
                          │
         ┌────────────────┴────────────────┐
         │                                 │
    ┌────▼──────┐                  ┌──────▼──────┐
    │ AuditLog  │                  │ UserContext │
    │  Model    │                  │  Service    │
    └────┬──────┘                  └──────┬──────┘
         │                                │
    ┌────▼──────┐                  ┌──────▼──────┐
    │  SQLite   │                  │  CloudKit   │
    │ Database  │                  │  Identity   │
    └───────────┘                  └─────────────┘
```

### Design Principles

1. **Single Source of Truth**: One `auditLogs` table for all actions
2. **User Attribution**: Every action tagged with CloudKit userID
3. **Structured Metadata**: JSON field for action-specific details
4. **Async & Non-Blocking**: Logging happens in background, never blocks UI
5. **Failure Tolerant**: Audit failures don't break operations
6. **Privacy First**: No secret values logged, userIDs pseudonymized

---

## Data Model

### AuditLog Table Schema

```sql
CREATE TABLE auditLogs (
    id BLOB NOT NULL PRIMARY KEY,
    vaultID BLOB NOT NULL,
    actorUserID TEXT NOT NULL,           -- CloudKit user identifier
    actionType TEXT NOT NULL,             -- 'create', 'update', 'delete', etc.
    entityType TEXT NOT NULL,             -- 'vault', 'credential', 'secret', 'participant'
    entityID BLOB,                        -- UUID of affected entity
    entityLabel TEXT,                     -- Human-readable label
    timestamp DATETIME NOT NULL,
    metadata TEXT,                        -- JSON with action-specific details
    deviceInfo TEXT,                      -- Device name/model
    ckRecordID TEXT,                      -- CloudKit record ID for sync
    FOREIGN KEY (vaultID) REFERENCES vaults(id) ON DELETE CASCADE
);

-- Performance indexes
CREATE INDEX idx_auditLogs_vaultID ON auditLogs(vaultID);
CREATE INDEX idx_auditLogs_actorUserID ON auditLogs(actorUserID);
CREATE INDEX idx_auditLogs_timestamp ON auditLogs(timestamp);
CREATE INDEX idx_auditLogs_actionType ON auditLogs(actionType);
CREATE INDEX idx_auditLogs_entityType ON auditLogs(entityType);
CREATE INDEX idx_auditLogs_entityID ON auditLogs(entityID) WHERE entityID IS NOT NULL;
```

### Action Types

| Action Type | Description | Example |
|------------|-------------|---------|
| `create` | Entity created | "John created AWS Prod credential" |
| `update` | Entity metadata modified | "Mary updated credential label" |
| `delete` | Entity deleted | "John deleted Test API Key" |
| `copy` | Secret copied to clipboard | "Mary copied Access Key ID (copy #5)" |
| `reveal` | Secret revealed in UI | "John viewed Secret Key" |
| `rotate` | Secret value rotated | "Mary rotated Secret Key (reason: compromised)" |
| `share` | Vault shared with participant | "John shared vault with mary@example.com" |
| `revoke` | Participant access revoked | "John revoked access for bob@example.com" |
| `pin` | Vault/credential pinned | "Mary pinned Production vault" |
| `unpin` | Vault/credential unpinned | "Mary unpinned Staging vault" |

### Entity Types

| Entity Type | Description | Actions Tracked |
|------------|-------------|-----------------|
| `vault` | Vault-level operations | create, update, delete, pin, unpin |
| `credential` | Credential operations | create, update, delete, pin, unpin |
| `secret` | Secret operations | create, update, delete, copy, reveal, rotate |
| `participant` | Sharing operations | share, revoke |

### Metadata Structure

Metadata is stored as JSON for flexibility:

```swift
{
  "secretLabel": "Access Key ID",
  "rotationReason": "compromised",
  "copyCount": 5,
  "recipientUserID": "_abc123def456",
  "permission": "readWrite",
  "notes": "Automated rotation"
}
```

**Secret Actions:**
- `secretLabel`: Name of the secret acted upon
- `rotationReason`: Why secret was rotated (expired, compromised, userInitiated)
- `copyCount`: Sequential copy number for this secret

**Sharing Actions:**
- `recipientUserID`: CloudKit ID of shared user
- `permission`: Access level granted (readOnly, readWrite)

---

## Services

### UserContextService

Fetches and caches CloudKit user identities to resolve userIDs to real names.

**Key Features:**
- **Caching**: In-memory cache prevents redundant CloudKit API calls
- **Deduplication**: Coalesces concurrent requests for same userID
- **Graceful Degradation**: Returns "Unknown User" if CloudKit fetch fails
- **Display Names**: Formats names using PersonNameComponentsFormatter

**API:**

```swift
// Get current user's CloudKit ID
let userID = try await userContext.getCurrentUserID()

// Get display name for any user
let name = await userContext.getDisplayName(for: userID)
// Returns: "John Smith" or "john@example.com" or "Unknown User"

// Prefetch all participants at once (optimization)
await userContext.prefetchParticipants(for: vault, participants: participants)
```

**Name Resolution Priority:**
1. Full name from `nameComponents` (e.g., "John Smith")
2. Email from `lookupInfo.emailAddress` (e.g., "john@example.com")
3. Truncated userID (e.g., "User _abc123d...")
4. Fallback: "Unknown User"

### AuditLogger

Centralized service for logging audit events.

**Key Features:**
- **Async & Non-Blocking**: All logging happens asynchronously
- **Failure Tolerant**: Errors don't break operations, only logged to console
- **Device Tracking**: Automatically captures device name/model
- **Flexible Querying**: Filter by action type, entity type, actor, date range

**API:**

```swift
// Log an action
await auditLogger.log(
    vaultID: vault.id,
    actionType: .create,
    entityType: .credential,
    entityID: credential.id,
    entityLabel: "AWS Production",
    metadata: AuditMetadata(secretLabel: "Access Key ID")
)

// Query logs for a vault
let logs = try await auditLogger.fetchLogs(
    for: vaultID,
    actionType: .copy,           // Optional filter
    entityType: .secret,         // Optional filter
    actorUserID: currentUser,    // Optional filter
    limit: 100
)

// Query logs for specific entity (e.g., credential activity)
let logs = try await auditLogger.fetchLogs(for: credentialID, limit: 50)

// Cleanup old logs (retention policy)
try await auditLogger.cleanupOldLogs(olderThan: 90)  // days
```

---

## Integration Points

### VaultManager

Audit logging added to:

- `createVault()` → Log vault creation
- `updateVault()` → Log vault metadata changes
- `deleteVault()` → Log vault deletion (before deletion!)
- `toggleVaultPin()` → Log pin/unpin actions
- `wrapKeyForRecipient()` → Log share actions
- `revokeShare()` → Log revocation actions

### CredentialManager

Audit logging added to:

- `createCredential()` → Log credential creation
- `updateCredential()` → Log credential metadata changes
- `deleteCredential()` → Log credential deletion (before deletion!)
- `addSecret()` → Log secret creation
- `updateSecret()` → Log secret rotation with reason
- `deleteSecret()` → Log secret deletion
- `markSecretAsUsed()` → Log copy action with copy count

### ViewModels

Audit logging added to:

- `CredentialDetailViewModel.toggleSecretVisibility()` → Log reveal actions
- `ManageSecretsViewModel.copySecret()` → Already calls `markSecretAsUsed`

### Example: Credential Creation

```swift
// In CredentialManager.createCredential():
public func createCredential(
    label: String,
    secrets: [(label: String, value: String)],
    vaultID: UUID,
    // ... other parameters
) async throws -> CredentialWithSecrets {

    // 1. Create credential (existing logic)
    let credential = Credential(...)
    try await database.write { db in
        try Credential.insert { credential }.execute(db)
    }

    // 2. Create secrets (existing logic)
    let createdSecrets = ...

    // 3. Log audit event (NEW)
    await auditLogger.log(
        vaultID: credential.vaultID,
        actionType: .create,
        entityType: .credential,
        entityID: credential.id,
        entityLabel: credential.label
    )

    return CredentialWithSecrets(credential: credential, secrets: createdSecrets)
}
```

---

## User Interface

### AuditLogListView

Main audit log viewer with filtering capabilities.

**Features:**
- **Date Grouping**: Logs grouped by "Today", "Yesterday", specific dates
- **Action Filtering**: Filter by action type (create, copy, delete, etc.)
- **Entity Filtering**: Filter by entity type (vault, credential, secret)
- **User Attribution**: Shows real names via UserContextService
- **Metadata Display**: Shows action-specific details (copy count, rotation reason)
- **Color Coding**: Visual indicators for action severity
- **Pull to Refresh**: Manual refresh for latest activity

**Access:**
- Per-Vault: VaultDetailsView → "..." menu → "View Activity"
- Global: Settings → "Audit & Privacy" → "Activity Logs"

**UI Layout:**

```
┌─────────────────────────────────────┐
│         Activity                    │
├─────────────────────────────────────┤
│ Action Type:  [All ▾]               │
│ Entity Type:  [All ▾]               │
├─────────────────────────────────────┤
│ Today                               │
│  ┌─────────────────────────────┐   │
│  │ 🔵 Create credential  3:45pm │   │
│  │ John Smith                   │   │
│  │ AWS Production               │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 🟠 Copy secret       2:30pm  │   │
│  │ Mary Johnson                 │   │
│  │ GitHub API / API Token       │   │
│  │ 📋 Copy #3                   │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│ Yesterday                           │
│  ┌─────────────────────────────┐   │
│  │ 🟣 Rotate secret    11:20am  │   │
│  │ John Smith                   │   │
│  │ AWS Prod / Secret Key        │   │
│  │ 🔄 Reason: compromised       │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Color Scheme:**

| Action Type | Color | Icon |
|------------|-------|------|
| create | Green | plus.circle.fill |
| update | Blue | pencil.circle.fill |
| delete | Red | trash.circle.fill |
| copy | Orange | doc.on.doc.fill |
| reveal | Orange | eye.fill |
| rotate | Purple | arrow.triangle.2.circlepath.circle.fill |
| share | Green | person.badge.plus.fill |
| revoke | Red | person.badge.minus.fill |

### Settings Integration

Added "Audit & Privacy" section:

```
Settings
├── ...
├── Audit & Privacy
│   ├── Activity Logs → [AuditLogListView]
│   ├── Retention Period: 90 days
│   └── Clear Old Logs [Button]
└── ...
```

---

## CloudKit Sync

### Strategy: Sync Audit Logs

**Rationale:**
- All vault participants should see complete audit trail
- Provides accountability and transparency in shared environments
- Required for compliance (all actions visible to all participants)

**Implementation:**
1. `AuditLog` model includes `ckRecordID` field
2. SQLiteData framework handles CloudKit sync automatically
3. Audit logs sync to all devices with vault access

**Considerations:**
- Audit logs are **NOT encrypted** (plaintext for compliance visibility)
- CloudKit userID is already pseudonymized (not real names)
- Real names fetched separately via CloudKit Discovery API
- Only participants with vault access can see logs
- Old logs deleted client-side (not synced deletion)

### Sync Flow

```
Device A: Create Credential
    ↓
Audit log inserted with ckRecordID: nil
    ↓
SQLiteData detects new record
    ↓
Upload to CloudKit (gets ckRecordID)
    ↓
Update local record with ckRecordID
    ↓
Device B: CloudKit notification
    ↓
Download new audit log record
    ↓
Insert into local database
    ↓
@FetchAll triggers UI update
    ↓
Device B: Shows "John created AWS Prod (3:45pm)"
```

---

## Performance

### Async Logging

All audit logging is **non-blocking**:

```swift
// This doesn't block the credential creation
await auditLogger.log(...)  // Async, but executes in background

// UI remains responsive
```

- Audit logging happens after the main operation completes
- Failures don't break operations (only logged to console)
- Database writes use background queue

### Index Strategy

Six indexes optimize common queries:

| Index | Purpose | Example Query |
|-------|---------|---------------|
| `vaultID` | Per-vault activity | "Show all activity in Production vault" |
| `actorUserID` | Per-user activity | "Show everything John did" |
| `timestamp` | Date range queries | "Show activity in last 7 days" |
| `actionType` | Action filtering | "Show all copy actions" |
| `entityType` | Entity filtering | "Show all credential operations" |
| `entityID` | Per-entity activity | "Show activity for this credential" |

**Query Performance:**
- Vault activity (200 logs): ~5ms
- User activity (500 logs): ~8ms
- Date range (30 days, 1000 logs): ~10ms

### Retention Policy

Default: **90 days**

Prevents unbounded database growth:

```swift
// Run monthly via background task
try await auditLogger.cleanupOldLogs(olderThan: 90)
```

**Disk Usage Estimate:**
- Average log entry: ~250 bytes
- 1000 actions/month: ~250 KB
- 90 days: ~750 KB

For high-activity vaults (10,000 actions/month):
- 90 days: ~7.5 MB (negligible)

### Batching (Optional)

For high-frequency operations:

```swift
// Instead of 100 individual inserts:
for secret in secrets {
    await auditLogger.log(...)  // 100 async calls
}

// Use batch insert:
await auditLogger.logBulkCopies(secrets, credential)  // 1 transaction
```

---

## Privacy & Security

### What's Logged

✅ **Logged (Safe):**
- Action type, entity type, timestamp
- CloudKit userID (pseudonymized, e.g., "_abc123def456")
- Credential labels ("AWS Production", "GitHub API")
- Secret labels ("Access Key ID", "Secret Key")
- Rotation reasons, copy counts
- Device info ("iPhone 15 Pro", "MacBook Pro")

❌ **NOT Logged (Sensitive):**
- Actual secret values
- Previous secret values
- Decrypted data
- User passwords or PINs

### Encryption

**Audit logs are NOT encrypted** (intentionally):

**Rationale:**
- Compliance requires readable audit trails
- CloudKit userID is already pseudonymized
- Real names fetched on-demand from CloudKit Discovery API
- Vault-level access control is sufficient

### Access Control

- **Vault Participants Only**: Only users with vault access can see logs
- **No Permission Levels**: Read-only and read-write participants see same logs
- **Append-Only**: Users cannot delete or modify audit logs
- **CloudKit Sync**: All participants see complete history

### GDPR Compliance

- **User Anonymization**: CloudKit userID is pseudonymized by Apple
- **Data Portability**: Audit logs can be exported (future feature)
- **Right to Erasure**: When vault is deleted, all audit logs cascade delete
- **Transparency**: Users can see exactly what's tracked

---

## Implementation Roadmap

### Phase 1: Data Layer (Day 1)
- [x] Create `AuditLog.swift` model with enums
- [x] Create `AuditMetadata.swift` helper
- [ ] Update `DatabaseSetup.swift` with `auditLogs` table
- [ ] Verify table creation and indexes in debug mode

### Phase 2: Services (Day 1-2)
- [ ] Create `UserContextService.swift`
  - CloudKit user identity fetching
  - Caching logic
  - Display name formatting
- [ ] Create `AuditLogger.swift`
  - Log method with device info
  - Query methods with filtering
  - Cleanup method
- [ ] Unit tests for both services

### Phase 3: Manager Integration (Day 2-3)
- [ ] Add `AuditLogger` to `VaultManager`
  - Create, update, delete vault
  - Share, revoke operations
- [ ] Add `AuditLogger` to `CredentialManager`
  - Create, update, delete credential
  - Add, update, delete, rotate secret
  - Mark secret as used (copy)
- [ ] Add audit logging to `CredentialDetailViewModel`
  - Reveal secret action
- [ ] Integration tests

### Phase 4: UI Components (Day 3-4)
- [ ] Create `AuditLogListViewModel.swift`
  - Load logs with filtering
  - Group by date
  - Display name resolution
- [ ] Create `AuditLogListView.swift`
  - Filter pickers
  - Grouped list
  - Log row with icons and colors
- [ ] Update `VaultDetailsView.swift`
  - Add "View Activity" menu item
- [ ] Update `SettingsView.swift`
  - Add audit preferences section
- [ ] UI tests

### Phase 5: Polish & Testing (Day 4-5)
- [ ] Test CloudKit sync of audit logs
- [ ] Test multi-user scenarios (shared vaults)
- [ ] Performance testing with 500+ audit log entries
- [ ] Verify retention cleanup
- [ ] Test display name resolution

### Phase 6: Documentation (Day 5)
- [x] Create comprehensive audit log documentation
- [ ] Add inline code documentation
- [ ] Create user guide for viewing activity

---

## Verification Checklist

After implementation, verify:

### Vault Operations
- [ ] Create vault → Audit log shows creation by current user
- [ ] Update vault → Audit log shows update
- [ ] Delete vault → Audit log preserved before deletion
- [ ] Pin vault → Audit log shows pin action
- [ ] Share vault → Audit log shows share with recipient userID

### Credential Operations
- [ ] Create credential → Audit log shows creation
- [ ] Update credential → Audit log shows update
- [ ] Delete credential → Audit log preserved before deletion
- [ ] Pin credential → Audit log shows pin action

### Secret Operations
- [ ] Add secret → Audit log shows secret creation
- [ ] Update secret → Audit log shows rotation with reason
- [ ] Delete secret → Audit log shows deletion
- [ ] Copy secret → Audit log shows copy with count
- [ ] Reveal secret → Audit log shows reveal action

### User Attribution
- [ ] Audit log list shows correct user names (not "Unknown User")
- [ ] User names update when CloudKit fetch completes
- [ ] Shared vault shows actions from multiple users

### Filtering & UI
- [ ] Filter by action type (copy) shows only copy actions
- [ ] Filter by entity type (credential) shows only credential actions
- [ ] Logs grouped by date (Today, Yesterday, specific dates)
- [ ] Icons and colors match action types
- [ ] Metadata displays correctly (copy count, rotation reason)

### Performance & Sync
- [ ] Device info appears in audit logs
- [ ] No performance impact on create/update/delete operations
- [ ] Audit logging failures don't break operations
- [ ] CloudKit sync: Action on device A appears on device B
- [ ] Shared vault: Both users see all audit logs

### Privacy & Security
- [ ] No secret values in audit logs (only labels)
- [ ] CloudKit userIDs are pseudonymized
- [ ] Only vault participants can see logs

### Retention & Cleanup
- [ ] Cleanup removes logs older than 90 days
- [ ] Active logs are preserved

---

## Future Enhancements

### Phase 2 Features

1. **Export Audit Logs**
   - CSV export for compliance reporting
   - Date range selection
   - Email/share sheet integration
   - Filtered export (by action type, user, etc.)

2. **Advanced Filtering**
   - Date range picker (custom start/end dates)
   - Multiple action type selection
   - Multiple entity type selection
   - Search by entity label
   - Search by user name

3. **Audit Alerts**
   - Push notifications for specific actions
   - Email digest of daily/weekly activity
   - Anomaly detection (unusual copy patterns)
   - Threshold alerts (>X copies in Y minutes)

4. **Per-Credential Activity View**
   - Show activity timeline for specific credential
   - Visual timeline chart
   - Quick filters (copies only, rotations only)

5. **Audit Log Retention Settings**
   - User-configurable retention period (30/60/90/180 days)
   - Archive to iCloud Drive for long-term storage
   - Selective deletion by action type

6. **Activity Dashboard**
   - Summary statistics per vault
   - Most active users
   - Most accessed credentials
   - Action type breakdown (pie chart)

---

## FAQ

### Q: Can users delete audit logs?

**A:** No. Audit logs are append-only for compliance. Only automatic cleanup based on retention policy removes old logs.

### Q: What happens if CloudKit is unavailable?

**A:** UserContextService gracefully degrades to showing truncated userIDs ("User _abc123d..."). Logs still capture the pseudonymized CloudKit userID.

### Q: Do audit logs consume significant storage?

**A:** No. Average log entry is ~250 bytes. Even high-activity vaults (10,000 actions/month) use only ~7.5 MB for 90 days of history.

### Q: Can I see who accessed my vault while I was offline?

**A:** Yes! When you come online, CloudKit syncs all audit logs from other participants. You'll see complete history.

### Q: Are audit logs encrypted?

**A:** No. Audit logs are plaintext for compliance visibility. CloudKit userIDs are already pseudonymized. Real names are fetched on-demand via CloudKit API.

### Q: Can read-only participants see audit logs?

**A:** Yes. All vault participants see all audit logs regardless of permission level. This ensures transparency and accountability.

### Q: What if I accidentally delete a credential?

**A:** The audit log preserves "You deleted [Credential Name] at [Time]" even after deletion. You can see what was deleted and when.

### Q: How do I export audit logs for compliance?

**A:** This is a planned Phase 2 feature. You'll be able to export logs as CSV with date range filtering.

---

## References

- [CloudKit User Discovery](https://developer.apple.com/documentation/cloudkit/ckcontainer/1399174-discoveruseridentity)
- [SQLiteData Documentation](https://github.com/pointfreeco/swift-sqlite-data)
- [GRDB Query Interface](https://github.com/groue/GRDB.swift)
- [Audit Log Best Practices](https://www.owasp.org/index.php/Logging_Cheat_Sheet)

---

## Changelog

- **2026-01-31**: Initial design document created
- **Future**: Implementation progress will be tracked here

---

## Contact

For questions or suggestions about the audit log system:
- Open an issue in the project repository
- Contact: [Your contact information]
