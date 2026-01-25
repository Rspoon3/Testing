# iCloud Sync Testing Guide

This document outlines how to test iCloud sync functionality for the TestDrive API Key Manager app.

## Prerequisites

1. **Two Devices Required:**
   - iPhone/iPad (Device A)
   - iPhone/iPad/Mac (Device B)
   - Both signed in to the same iCloud account

2. **iCloud Drive Enabled:**
   - Settings → [Your Name] → iCloud → iCloud Drive → ON
   - Ensure app has iCloud permissions

3. **Network Connectivity:**
   - Both devices connected to internet
   - Stable connection recommended

## Test Scenarios

### Scenario 1: Basic Sync - Create Vault on Device A

**Steps:**
1. Launch app on Device A
2. Create new vault "Test Sync Vault"
   - Icon: lock.fill
   - Color: Blue
3. Observe sync status indicator in toolbar
   - Should show "Syncing..." with spinner
   - Then "Synced" with green checkmark
4. Wait 10-30 seconds
5. Launch app on Device B
6. Pull to refresh on vault list
7. **Expected:** "Test Sync Vault" appears on Device B

**Success Criteria:**
- ✓ Vault appears on Device B within 30 seconds
- ✓ Icon and color match exactly
- ✓ Key count shows 0 on both devices

### Scenario 2: API Key Sync

**Steps:**
1. On Device A, open "Test Sync Vault"
2. Create new API key:
   - Label: "GitHub Sync Test"
   - Secret: "ghp_test123456"
   - Domain: "github.com"
   - Environment: Production
   - Tags: "sync", "test"
3. Observe sync indicator
4. On Device B, navigate to "Test Sync Vault"
5. Pull to refresh
6. **Expected:** "GitHub Sync Test" appears

**Success Criteria:**
- ✓ Key appears on Device B
- ✓ All metadata synced (domain, environment, tags)
- ✓ Can decrypt and view secret on Device B
- ✓ Secret matches original

### Scenario 3: Simultaneous Edits (Conflict Resolution)

**Steps:**
1. On Device A, open existing vault "Test Sync Vault"
2. Edit vault name to "Sync Test A"
3. **IMMEDIATELY** on Device B, edit same vault to "Sync Test B"
4. Wait 30 seconds for sync
5. Pull to refresh on both devices
6. **Expected:** Most recent edit wins (check updatedAt timestamp)

**Success Criteria:**
- ✓ Both devices converge to same vault name
- ✓ No duplicate vaults created
- ✓ Most recent update preserved

### Scenario 4: Offline Editing

**Steps:**
1. On Device A, enable Airplane Mode
2. Create new vault "Offline Vault"
3. Create API key "Offline Key" with secret
4. Observe sync status shows "No connection" or similar
5. Disable Airplane Mode
6. Wait 30 seconds
7. Pull to refresh
8. On Device B, pull to refresh
9. **Expected:** "Offline Vault" and "Offline Key" appear on Device B

**Success Criteria:**
- ✓ Changes queued while offline
- ✓ Automatic sync when back online
- ✓ All data arrives intact

### Scenario 5: Delete Sync

**Steps:**
1. On Device A, delete vault "Test Sync Vault"
2. Observe sync indicator
3. On Device B, pull to refresh
4. **Expected:** Vault disappears from Device B

**Success Criteria:**
- ✓ Vault removed on Device B
- ✓ All keys in vault also removed
- ✓ No orphaned data

### Scenario 6: Large Data Sync

**Steps:**
1. On Device A, create 50 API keys in a vault
   - Use script or rapid creation
2. Observe sync process
3. On Device B, pull to refresh
4. **Expected:** All 50 keys appear

**Success Criteria:**
- ✓ All keys synced successfully
- ✓ Count matches on both devices
- ✓ No data loss
- ✓ Reasonable sync time (< 2 minutes)

### Scenario 7: Metadata Update Sync

**Steps:**
1. On Device A, edit existing key "GitHub Sync Test"
2. Change:
   - Add tag "updated"
   - Update notes "Edited on Device A"
   - Change environment to Staging
3. Save changes
4. On Device B, pull to refresh
5. Open same key
6. **Expected:** All metadata changes reflected

**Success Criteria:**
- ✓ Tags updated
- ✓ Notes updated
- ✓ Environment badge shows Staging (orange)
- ✓ Secret unchanged

## Conflict Resolution Rules

### Vault Conflicts
- **Strategy:** Most recent `updatedAt` timestamp wins
- **Example:** If Device A updates at 10:01 and Device B at 10:02, Device B's version wins

### API Key Conflicts
- **Strategy:** Most recent `createdAt` wins; if equal, prefer more complete metadata
- **Metadata Score:** Domain + Company + Tags + Notes + Rotation + Last Used

### Delete Conflicts
- **Strategy:** Delete always wins over update
- **Example:** If Device A deletes while Device B edits, the record is deleted

## Troubleshooting

### Sync Not Working

**Check:**
1. iCloud account signed in (Settings → [Your Name])
2. iCloud Drive enabled for app
3. Network connectivity (Settings → Cellular/Wi-Fi)
4. Storage space available on iCloud
5. CloudKit Console for errors

**Steps:**
1. Force quit app on both devices
2. Relaunch
3. Pull to refresh
4. Check sync status indicator

### Duplicate Records

**Cause:** Rare race condition during simultaneous creation
**Fix:** Delete duplicate manually; fixed in next sync

### Missing Data

**Check:**
1. Sync status indicator for errors
2. Pull to refresh manually
3. Check other device hasn't deleted
4. Verify iCloud storage not full

## Performance Benchmarks

### Expected Sync Times
- **Single vault:** < 5 seconds
- **Single API key:** < 5 seconds
- **10 keys:** < 15 seconds
- **50 keys:** < 60 seconds
- **100 keys:** < 2 minutes

### Network Usage
- **Initial sync (empty):** ~10 KB
- **Per vault:** ~1 KB
- **Per API key:** ~2-5 KB (depending on metadata)

## CloudKit Console Monitoring

**Access:** https://icloud.developer.apple.com/dashboard

**Steps:**
1. Sign in with Apple ID
2. Select "TestDrive" app
3. Navigate to CloudKit Dashboard
4. View:
   - Records (Vault, APIKey, VaultParticipant, WrappedVaultKey)
   - Sync activity
   - Error logs

**Useful Queries:**
```
# Find all vaults
recordType = "Vault"

# Find keys in specific vault
recordType = "APIKey" AND vaultID = "..."

# Find shared vaults
recordType = "Vault" AND isShared = true
```

## Debugging Tips

### Enable Verbose Logging
```swift
// In DatabaseManager.swift
#if DEBUG
print("Sync started: \(Date())")
print("Sync completed: \(Date())")
print("Sync error: \(error)")
#endif
```

### Check Local Database
```swift
// Use database inspection tool
let keys = try await database.read { db in
    // Query all records
}
print("Local keys count: \(keys.count)")
```

### Monitor Network Activity
- Use Xcode Network debugging
- Charles Proxy for CloudKit traffic
- CloudKit Dashboard for server-side view

## Common Issues

### Issue: "iCloud not available"
**Solution:** Enable iCloud Drive in Settings

### Issue: Sync stuck in "Syncing..." state
**Solution:** Force quit app, clear cache, relaunch

### Issue: Old data reappearing
**Solution:** CloudKit propagation delay; wait 60 seconds and refresh

### Issue: Conflict loop (data keeps changing)
**Solution:** Check timestamps; ensure devices have correct time

## Success Metrics

A successful sync implementation should achieve:
- ✓ 95%+ sync success rate
- ✓ < 30 second sync latency
- ✓ 0 data loss incidents
- ✓ Proper conflict resolution (no duplicates)
- ✓ Seamless offline/online transition

## Next Steps After Sync Testing

1. **Phase 6:** Test vault sharing with different iCloud accounts
2. **Phase 7:** Implement security warnings
3. **Phase 8:** Performance optimization and polish
