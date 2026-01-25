# CloudKit Setup Guide

This guide covers the necessary CloudKit and iCloud configuration for TestDrive's sync functionality.

## Prerequisites

- Apple Developer Account (required for CloudKit)
- Xcode 15.0 or later
- iOS 18.0 deployment target

## Step 1: Enable iCloud Capability

### In Xcode

1. Select project in navigator
2. Select "TestDrive" target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "iCloud"

### Configure iCloud Services

Check the following services:
- ✓ **CloudKit** (required)
- ✓ **CloudKit Database** (required)

### Container Configuration

1. Click "+" under "Containers"
2. Select "iCloud.com.rspoon3.TestDrive"
   - Or create new: "iCloud.$(CFBundleIdentifier)"
3. Ensure container is checked

## Step 2: Entitlements File

The `TestDrive.entitlements` file should contain:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.rspoon3.TestDrive</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    <key>com.apple.developer.ubiquity-container-identifiers</key>
    <array>
        <string>iCloud.com.rspoon3.TestDrive</string>
    </array>
</dict>
</plist>
```

## Step 3: CloudKit Schema

SQLiteData automatically creates the schema, but here's what it creates:

### Record Types

**Vault**
- id: String (indexed)
- name: String
- iconName: String
- colorHex: String
- sortOrder: Int64
- isDefault: Int64
- createdAt: Date/Time
- updatedAt: Date/Time
- ownerPublicKey: Bytes
- isShared: Int64
- ownerUserID: String (optional)

**APIKey**
- id: String (indexed)
- label: String
- websiteDomain: String (optional)
- company: String (optional)
- environment: String
- tags: String (JSON array)
- createdAt: Date/Time
- rotateAt: Date/Time (optional)
- lastUsedAt: Date/Time (optional)
- notes: String
- vaultID: String (indexed, reference to Vault)
- encryptedSecret: Bytes
- nonce: Bytes

**VaultParticipant**
- id: String (indexed)
- vaultID: String (indexed, reference to Vault)
- userID: String
- publicKey: Bytes (optional)
- permission: String
- acceptanceStatus: String
- addedAt: Date/Time

**WrappedVaultKey**
- id: String (indexed)
- vaultID: String (indexed, reference to Vault)
- recipientUserID: String
- encryptedVaultKey: Bytes
- ephemeralPublicKey: Bytes
- wrappedAt: Date/Time

### Indexes

- Vault.id (queryable)
- APIKey.id (queryable)
- APIKey.vaultID (queryable)
- VaultParticipant.vaultID (queryable)
- WrappedVaultKey.vaultID (queryable)

## Step 4: CloudKit Dashboard Configuration

### Access Dashboard

1. Go to https://icloud.developer.apple.com/dashboard
2. Sign in with Apple ID
3. Select "TestDrive" app
4. Navigate to "CloudKit Database"

### Development vs Production

**Development:**
- Used for testing
- Can reset schema
- Separate data from production

**Production:**
- Live user data
- Schema cannot be reset
- Deploy after thorough testing

### Security Roles

**Default Roles (automatically configured by SQLiteData):**

- **World:** Read only for public data (not used in this app)
- **Authenticated:** Read/Write for user's own records
- **Creator:** Full access to records user created

## Step 5: Testing CloudKit Connection

### In Simulator

**Note:** CloudKit sync does NOT work in Simulator
- Simulator doesn't support iCloud sync
- Must test on physical devices

### On Device

1. Build and run on physical iPhone/iPad
2. Ensure signed into iCloud (Settings → [Your Name])
3. Launch app
4. Create a vault
5. Check CloudKit Dashboard for new record

### Verification Steps

```bash
# Check console logs for CloudKit activity
# Look for:
# - "CKContainer: initialized"
# - "CloudKit sync started"
# - "Record saved: Vault/..."
```

## Step 6: Multi-Device Setup

### Device A (iPhone)

1. Sign in to iCloud with Account A
2. Install TestDrive
3. Create vault "Device A Test"
4. Verify sync status shows "Synced"

### Device B (iPad)

1. Sign in to iCloud with Account A (same account)
2. Install TestDrive
3. Pull to refresh
4. Verify "Device A Test" appears

## Common Setup Issues

### Issue: "CloudKit not available"

**Causes:**
- Not signed into iCloud
- iCloud Drive disabled
- Network connection issues
- Developer account issues

**Solutions:**
1. Check Settings → [Your Name] → iCloud → iCloud Drive (ON)
2. Verify network connection
3. Check Apple Developer account status
4. Verify container ID matches

### Issue: "Container not found"

**Cause:** Container ID mismatch

**Solution:**
1. Check entitlements file
2. Verify container ID in Xcode capabilities
3. Ensure container created in CloudKit Dashboard
4. Check for typos in identifier

### Issue: "Permission denied"

**Cause:** Security role misconfiguration

**Solution:**
1. Open CloudKit Dashboard
2. Go to Security Roles
3. Verify "Authenticated" role has read/write
4. Save and redeploy

### Issue: Records not syncing

**Causes:**
- Schema not deployed
- Network issues
- Conflicting records

**Solutions:**
1. Deploy schema from Dashboard
2. Check network connectivity
3. Review CloudKit Console logs
4. Reset Development environment if needed

## Development vs Production Checklist

### Before Production Deployment

- [ ] Test sync on multiple devices
- [ ] Test with poor network conditions
- [ ] Test conflict resolution
- [ ] Verify all record types save correctly
- [ ] Test sharing functionality
- [ ] Review CloudKit usage limits
- [ ] Deploy schema to production
- [ ] Test with production container
- [ ] Monitor initial rollout

### CloudKit Quotas

**Free Tier (per user):**
- 10 GB of asset storage
- 100 MB of database storage
- 2 GB/day of data transfer
- 40 requests/second

**Important:** These limits are per-user, not per-app

## Monitoring and Debugging

### CloudKit Console

**Monitor:**
- Record counts
- Sync activity
- Error rates
- Network usage

**Actions:**
- Query records
- Edit records (development only)
- Reset schema (development only)
- View logs

### App-Side Logging

Enable CloudKit logging in DatabaseManager:

```swift
#if DEBUG
let database = try Database(path: fileURL.path, logging: true)
#else
let database = try Database(path: fileURL.path)
#endif
```

### Xcode Console

Filter for CloudKit logs:
- "CKContainer"
- "CloudKit"
- "SyncEngine"

## Security Best Practices

1. **Never store sensitive data unencrypted**
   - API secrets are encrypted before CloudKit upload
   - Vault keys wrapped with user-specific keys

2. **Validate data on read**
   - Check data integrity after sync
   - Verify encryption hasn't been compromised

3. **Limit exposed metadata**
   - Only label, domain, company synced as plaintext
   - Secrets always encrypted

4. **Regular security audits**
   - Review CloudKit Dashboard regularly
   - Monitor for unusual sync patterns

## Production Deployment

### Pre-Launch Checklist

- [ ] Schema deployed to production
- [ ] Testing completed with production container
- [ ] Monitoring dashboard configured
- [ ] Backup strategy in place
- [ ] Rollback plan documented
- [ ] Support documentation ready

### Launch Day

1. Deploy app to App Store
2. Monitor CloudKit Dashboard
3. Watch for sync errors
4. Respond to user feedback quickly

### Post-Launch

- Monitor daily for first week
- Review CloudKit usage metrics
- Address any sync issues promptly
- Gather user feedback on sync experience

## Additional Resources

- [CloudKit Documentation](https://developer.apple.com/icloud/cloudkit/)
- [SQLiteData GitHub](https://github.com/pointfreeco/sqlite-data)
- [WWDC CloudKit Sessions](https://developer.apple.com/videos/frameworks/cloudkit)
- [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
