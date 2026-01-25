# TestDrive Manual Testing Checklist

This document provides a comprehensive manual testing checklist for TestDrive before release.

## Pre-Testing Setup

- [ ] Two iOS devices (Device A and Device B)
- [ ] Different iCloud accounts (Account A and Account B)
- [ ] TestDrive installed on both devices
- [ ] Both devices connected to internet
- [ ] iCloud Drive enabled on both accounts
- [ ] TestFlight or development build installed

## Phase 1: Core Functionality

### Vault Management

#### Create Vault
- [ ] Launch app for first time
- [ ] See empty state with helpful message
- [ ] Tap "+" button in toolbar
- [ ] **Expected**: Create vault sheet appears
- [ ] Enter vault name "Personal APIs"
- [ ] Select icon (e.g., "key.fill")
- [ ] Select color (e.g., blue)
- [ ] Tap "Create"
- [ ] **Expected**: Sheet dismisses, vault appears in list
- [ ] **Expected**: Vault shows correct name, icon, color
- [ ] **Expected**: Key count shows "0 keys"

#### Create Multiple Vaults
- [ ] Create second vault "Work APIs"
- [ ] Create third vault "Test Keys"
- [ ] **Expected**: All three vaults visible in list
- [ ] **Expected**: Each maintains its own icon and color

#### Edit Vault
- [ ] Long press on vault or swipe left
- [ ] Tap "Edit" (if implemented) or navigate to settings
- [ ] Change vault name
- [ ] Change icon
- [ ] Change color
- [ ] **Expected**: Changes persist after save

#### Delete Vault
- [ ] Swipe left on empty vault
- [ ] Tap "Delete"
- [ ] **Expected**: Confirmation alert appears
- [ ] Tap "Cancel"
- [ ] **Expected**: Vault remains
- [ ] Swipe left again, tap "Delete", confirm
- [ ] **Expected**: Vault removed from list
- [ ] **Expected**: Smooth animation

### API Key Management

#### Create API Key
- [ ] Tap on "Personal APIs" vault
- [ ] **Expected**: Empty key list with "Add Key" button
- [ ] Tap "+" or "Add Key"
- [ ] **Expected**: Edit key sheet appears
- [ ] Fill in required fields:
  - Label: "GitHub Token"
  - Secret: "ghp_test1234567890abcdefghij"
- [ ] Fill in optional fields:
  - Domain: "github.com"
  - Company: "GitHub"
  - Environment: Production
  - Tags: "dev", "api"
  - Notes: "Personal access token for repositories"
- [ ] Tap "Save"
- [ ] **Expected**: Sheet dismisses
- [ ] **Expected**: Key appears in list
- [ ] **Expected**: Shows label, environment badge, tags

#### Create Multiple Keys
- [ ] Add "AWS Access Key" with production environment
- [ ] Add "Stripe Test Key" with testing environment
- [ ] Add "OpenAI API Key" with development environment
- [ ] **Expected**: All keys visible
- [ ] **Expected**: Different environment colors visible

#### View Key Details
- [ ] Tap on "GitHub Token"
- [ ] **Expected**: Detail view appears
- [ ] **Expected**: All metadata visible (label, domain, company, etc.)
- [ ] **Expected**: Secret field is masked (••••••)
- [ ] **Expected**: Tags displayed as chips
- [ ] **Expected**: Creation date shown
- [ ] **Expected**: Last used timestamp (if applicable)

#### Reveal Secret
- [ ] In key detail, tap "Show" button next to secret
- [ ] **Expected**: Secret becomes visible in full
- [ ] **Expected**: Button changes to "Hide"
- [ ] **Expected**: Haptic feedback (light tap)
- [ ] Tap "Hide"
- [ ] **Expected**: Secret masked again
- [ ] **Expected**: Haptic feedback

#### Copy Secret
- [ ] Tap "Copy" button
- [ ] **Expected**: Success haptic feedback
- [ ] **Expected**: Toast/banner notification appears
- [ ] **Expected**: Notification shows "Copied GitHub Token"
- [ ] **Expected**: Notification shows auto-clear countdown (e.g., "Will clear in 30s")
- [ ] Open Notes app and paste
- [ ] **Expected**: Secret pastes correctly
- [ ] Wait 30 seconds (or configured duration)
- [ ] Try to paste again
- [ ] **Expected**: Clipboard is empty

#### Edit API Key
- [ ] In key detail, tap "Edit"
- [ ] **Expected**: Edit sheet appears with all current values
- [ ] Change label to "GitHub Personal Token"
- [ ] Add new tag "github"
- [ ] Update notes
- [ ] Tap "Save"
- [ ] **Expected**: Changes reflected in detail view
- [ ] Go back to list
- [ ] **Expected**: Updated label shown in list

#### Delete API Key
- [ ] In key list, swipe left on a key
- [ ] Tap "Delete"
- [ ] **Expected**: Confirmation alert
- [ ] Tap "Cancel"
- [ ] **Expected**: Key remains
- [ ] Swipe left again, delete, confirm
- [ ] **Expected**: Warning haptic feedback
- [ ] **Expected**: Key removed with animation
- [ ] **Expected**: Success haptic after deletion

### Search and Filtering

#### Search Keys
- [ ] In key list, use search bar
- [ ] Type "git"
- [ ] **Expected**: Only "GitHub" keys visible
- [ ] **Expected**: Other keys filtered out
- [ ] Type "prod"
- [ ] **Expected**: Only production environment keys visible
- [ ] Clear search
- [ ] **Expected**: All keys reappear

#### Filter by Environment
- [ ] If environment filter implemented, test each option
- [ ] **Expected**: Only matching keys visible

## Phase 2: iCloud Sync

### Initial Sync Setup
- [ ] **Device A**: Create vault "Sync Test"
- [ ] **Device A**: Add key "Sync Key 1"
- [ ] **Device A**: Pull to refresh
- [ ] **Expected**: Sync status indicator shows syncing
- [ ] **Expected**: Sync completes successfully

### Cross-Device Sync (Create)
- [ ] **Device B**: Launch app
- [ ] **Device B**: Pull to refresh
- [ ] **Expected**: "Sync Test" vault appears within 30 seconds
- [ ] **Device B**: Open vault
- [ ] **Expected**: "Sync Key 1" visible
- [ ] **Device B**: Tap key, reveal secret
- [ ] **Expected**: Secret decrypts successfully
- [ ] **Expected**: Secret matches value from Device A

### Cross-Device Sync (Update)
- [ ] **Device B**: Edit "Sync Key 1"
- [ ] **Device B**: Change label to "Sync Key 1 Updated"
- [ ] **Device B**: Save changes
- [ ] **Device A**: Pull to refresh
- [ ] **Expected**: Updated label appears on Device A within 30 seconds

### Cross-Device Sync (Delete)
- [ ] **Device A**: Delete "Sync Key 1 Updated"
- [ ] **Device B**: Pull to refresh
- [ ] **Expected**: Key disappears from Device B

### Offline Sync
- [ ] **Device A**: Enable Airplane Mode
- [ ] **Device A**: Create key "Offline Key"
- [ ] **Expected**: Key appears locally
- [ ] **Expected**: Sync indicator shows "Offline" or waiting
- [ ] **Device A**: Disable Airplane Mode
- [ ] **Expected**: Automatic sync begins
- [ ] **Device B**: Pull to refresh
- [ ] **Expected**: "Offline Key" appears on Device B

### Conflict Resolution
- [ ] **Device A**: Enable Airplane Mode
- [ ] **Device B**: Enable Airplane Mode
- [ ] **Device A**: Edit key "Test Key" → change label to "Test Key A"
- [ ] **Device B**: Edit same key → change label to "Test Key B"
- [ ] **Device A**: Disable Airplane Mode, pull to refresh
- [ ] **Device B**: Disable Airplane Mode, pull to refresh
- [ ] **Expected**: Conflict resolved (most recent timestamp wins)
- [ ] **Expected**: Both devices show same final state
- [ ] **Expected**: No data loss

## Phase 3: Vault Sharing

### Share Creation
- [ ] **Device A**: Swipe left on "Shared Test Vault"
- [ ] Tap "Share"
- [ ] **Expected**: ShareVaultView appears
- [ ] Tap "Share Vault" button
- [ ] **Expected**: System CloudKit share sheet appears
- [ ] Enter Account B email/phone
- [ ] Select "Can Make Changes" permission
- [ ] Tap "Send"
- [ ] **Expected**: Share sheet dismisses
- [ ] **Expected**: Vault shows "Shared" indicator
- [ ] **Expected**: Owner participant appears in list

### Share Acceptance
- [ ] **Device B**: Receive notification (email/Messages/etc.)
- [ ] Tap invitation link
- [ ] **Expected**: Opens in TestDrive app
- [ ] **Expected**: Accept share prompt appears
- [ ] Tap "Accept"
- [ ] **Expected**: Vault appears in vault list
- [ ] **Expected**: Vault shows "Shared" indicator

### Recipient Access (Read & Write)
- [ ] **Device B**: Open shared vault
- [ ] **Expected**: All keys visible
- [ ] **Device B**: Tap a key
- [ ] **Expected**: Can view all metadata
- [ ] **Device B**: Reveal secret
- [ ] **Expected**: Secret decrypts successfully
- [ ] **Expected**: Secret matches owner's version
- [ ] **Device B**: Add new key "Recipient Key"
- [ ] **Expected**: Key created successfully
- [ ] **Device A**: Pull to refresh
- [ ] **Expected**: "Recipient Key" appears
- [ ] **Device A**: Reveal secret
- [ ] **Expected**: Secret decrypts successfully

### Participant Management
- [ ] **Device A**: Open vault share settings
- [ ] **Expected**: Participant list shows Account B
- [ ] **Expected**: Status shows "Active" (green)
- [ ] **Expected**: Permission shows "Read & Write"
- [ ] **Expected**: Green checkmark seal (key wrapped)

### Change Permissions
- [ ] **Device A**: Tap Account B permission menu
- [ ] Change to "Read Only"
- [ ] **Expected**: Permission updates immediately
- [ ] **Device B**: Pull to refresh
- [ ] **Device B**: Try to add new key
- [ ] **Expected**: Error or disabled (CloudKit enforces)
- [ ] **Device B**: Try to edit existing key
- [ ] **Expected**: Error or disabled

### Share Revocation
- [ ] **Device A**: Open share settings
- [ ] Tap Account B, select "Remove"
- [ ] **Expected**: Confirmation alert
- [ ] Confirm removal
- [ ] **Expected**: Participant removed from list
- [ ] **Expected**: Wrapped key deleted
- [ ] **Device B**: Pull to refresh
- [ ] **Expected**: Vault disappears from list
- [ ] **Expected**: Cannot access keys anymore

### Stop Sharing
- [ ] **Device A**: Share vault with Account B again
- [ ] **Device B**: Accept and verify access
- [ ] **Device A**: Open share settings
- [ ] Scroll to bottom, tap "Stop Sharing" (red button)
- [ ] **Expected**: Warning confirmation alert
- [ ] Confirm stop sharing
- [ ] **Expected**: All participants removed
- [ ] **Expected**: Vault becomes private again
- [ ] **Expected**: "Shared" indicator disappears
- [ ] **Device B**: Pull to refresh
- [ ] **Expected**: Vault removed

### Multiple Recipients
- [ ] **Device A**: Share vault with Account B and Account C
- [ ] **Expected**: Both accept invitations
- [ ] **Expected**: Both can view and decrypt keys
- [ ] **Device A**: Add new key
- [ ] **Expected**: Syncs to both recipients
- [ ] **Device B**: Add new key
- [ ] **Expected**: Syncs to Device A and Account C

## Phase 4: Security Features

### Security Warnings

#### Expired Keys
- [ ] Create key with rotation date in past
- [ ] Navigate to Security tab
- [ ] **Expected**: Warning appears with "Expired" badge (red)
- [ ] **Expected**: Shows days expired
- [ ] **Expected**: High severity icon
- [ ] Swipe to dismiss
- [ ] **Expected**: Warning removed

#### Keys Needing Rotation
- [ ] Create key with rotation date 3 days in future
- [ ] Navigate to Security tab
- [ ] **Expected**: Warning appears with orange badge
- [ ] **Expected**: Shows "Rotate in 3 days"
- [ ] **Expected**: Medium severity

#### Recent Clipboard Activity
- [ ] Copy a key secret
- [ ] Navigate to Security tab
- [ ] **Expected**: "Recently Copied" warning (blue, low severity)
- [ ] **Expected**: Shows time ago ("5 minutes ago")
- [ ] Wait 24+ hours
- [ ] Refresh Security tab
- [ ] **Expected**: Old clipboard activity removed

### Clipboard Settings

#### Auto-Clear Duration
- [ ] Navigate to Settings tab
- [ ] Tap "Auto-Clear Duration"
- [ ] Select "15 seconds"
- [ ] **Expected**: Setting saves
- [ ] Copy a secret
- [ ] Wait 15 seconds
- [ ] Try to paste
- [ ] **Expected**: Clipboard cleared
- [ ] Change duration to "Never"
- [ ] Copy a secret
- [ ] Wait 1 minute
- [ ] **Expected**: Secret still in clipboard

#### Clipboard Notifications
- [ ] Settings > Toggle "Show Notifications" ON
- [ ] Copy a secret
- [ ] **Expected**: Toast/banner notification appears
- [ ] Toggle "Show Notifications" OFF
- [ ] Copy another secret
- [ ] **Expected**: No notification (still copied)

## Phase 5: Settings & Configuration

### Theme Settings
- [ ] Settings > Appearance > Select "Light"
- [ ] **Expected**: App switches to light mode
- [ ] Select "Dark"
- [ ] **Expected**: App switches to dark mode
- [ ] Select "System"
- [ ] **Expected**: App matches system preference
- [ ] Change system setting
- [ ] **Expected**: App updates automatically

### Data Management

#### Export Data
- [ ] Settings > Tap "Export Data"
- [ ] **Expected**: Loading indicator appears
- [ ] **Expected**: Share sheet appears with JSON file
- [ ] Share to Files app or email
- [ ] Open exported JSON
- [ ] **Expected**: Contains vault metadata
- [ ] **Expected**: Contains key labels, domains, environments
- [ ] **Expected**: Does NOT contain secrets (security)
- [ ] **Expected**: Valid JSON format

#### Clear All Data
- [ ] Settings > Tap "Clear All Data"
- [ ] **Expected**: Warning confirmation alert
- [ ] **Expected**: Alert explains permanence
- [ ] Tap "Cancel"
- [ ] **Expected**: No data deleted
- [ ] Tap "Clear All Data" again, confirm
- [ ] **Expected**: Loading indicator
- [ ] **Expected**: All vaults deleted
- [ ] **Expected**: All keys deleted
- [ ] **Expected**: Clipboard cleared
- [ ] **Expected**: Returns to empty state
- [ ] Pull to refresh
- [ ] **Expected**: CloudKit synced deletion (vaults removed from other devices)

### About Section
- [ ] Settings > About section
- [ ] **Expected**: Shows correct version number
- [ ] **Expected**: Shows correct build number
- [ ] Tap GitHub link
- [ ] **Expected**: Opens repository in browser

## Phase 6: UI/UX Polish

### Animations
- [ ] Create vault
- [ ] **Expected**: Smooth fade-in animation
- [ ] Delete vault
- [ ] **Expected**: Smooth fade-out with spring animation
- [ ] Navigate to key detail
- [ ] **Expected**: Smooth push transition
- [ ] Open create sheet
- [ ] **Expected**: Smooth sheet presentation
- [ ] All transitions feel smooth (60fps)

### Haptic Feedback
- [ ] Reveal/hide secret
- [ ] **Expected**: Light haptic tap
- [ ] Copy secret
- [ ] **Expected**: Success haptic (double tap)
- [ ] Delete key
- [ ] **Expected**: Warning haptic
- [ ] Delete vault
- [ ] **Expected**: Warning haptic followed by success
- [ ] Error occurs
- [ ] **Expected**: Error haptic (triple tap)

### Loading States
- [ ] Launch app with slow network
- [ ] **Expected**: Loading view with spinner
- [ ] **Expected**: "Loading vaults..." message
- [ ] Export data
- [ ] **Expected**: Button shows "Exporting..."
- [ ] **Expected**: Spinner in button
- [ ] Clear all data
- [ ] **Expected**: Button shows "Clearing..."

### Empty States
- [ ] No vaults
- [ ] **Expected**: Helpful empty state with icon
- [ ] **Expected**: Message: "No vaults yet"
- [ ] **Expected**: Suggestion to create first vault
- [ ] No keys in vault
- [ ] **Expected**: Empty state with key icon
- [ ] **Expected**: Message encourages adding first key
- [ ] No security warnings
- [ ] **Expected**: "All Clear" message with shield icon

### Error Handling
- [ ] Disconnect internet, pull to refresh
- [ ] **Expected**: Error view appears
- [ ] **Expected**: Clear error message
- [ ] **Expected**: "Try Again" button
- [ ] Tap "Try Again"
- [ ] **Expected**: Retry action executes
- [ ] Create key with empty label
- [ ] **Expected**: Validation error inline
- [ ] **Expected**: Save button disabled

## Phase 7: Edge Cases

### Large Data Sets
- [ ] Create vault with 100+ keys
- [ ] **Expected**: List scrolls smoothly
- [ ] **Expected**: Search remains performant
- [ ] **Expected**: Sync completes successfully

### Special Characters
- [ ] Create key with emoji in label: "🔑 My Key"
- [ ] **Expected**: Displays correctly
- [ ] Create secret with special chars: `!@#$%^&*()[]{}|\":;<>,.?/~`
- [ ] **Expected**: Encrypts and decrypts correctly
- [ ] **Expected**: Copy/paste works

### Long Strings
- [ ] Create key with 500-character label
- [ ] **Expected**: Truncates in list, shows full in detail
- [ ] Create 10,000-character secret
- [ ] **Expected**: Encrypts successfully
- [ ] **Expected**: Decrypts successfully
- [ ] **Expected**: Copy/paste works

### Network Conditions
- [ ] Poor network: Create key
- [ ] **Expected**: Creates locally, syncs when able
- [ ] **Expected**: Sync indicator shows waiting
- [ ] No network: Try to accept share
- [ ] **Expected**: Error message or queued for later

### Rapid Actions
- [ ] Rapidly tap "Create Vault" multiple times
- [ ] **Expected**: Only one sheet appears
- [ ] Rapidly copy secret multiple times
- [ ] **Expected**: Each copy resets auto-clear timer
- [ ] Rapidly reveal/hide secret
- [ ] **Expected**: State updates correctly, no crashes

### Background/Foreground
- [ ] Copy secret
- [ ] Immediately background app
- [ ] Wait 30 seconds
- [ ] Return to app
- [ ] Try to paste
- [ ] **Expected**: Clipboard cleared (background timer worked)
- [ ] Edit key, don't save
- [ ] Background app
- [ ] Return to app
- [ ] **Expected**: Draft state preserved or lost (document behavior)

## Phase 8: Performance

### Startup Time
- [ ] Force quit app
- [ ] Launch app
- [ ] **Expected**: App launches in < 2 seconds
- [ ] **Expected**: Vaults visible immediately (from cache)
- [ ] **Expected**: Background sync starts automatically

### Responsiveness
- [ ] All button taps respond instantly
- [ ] List scrolling is smooth (60fps)
- [ ] Search filtering is instant
- [ ] Sheet presentations are smooth
- [ ] No frame drops during animations

### Memory Usage
- [ ] Open Activity Monitor / Instruments
- [ ] Navigate through app
- [ ] Create/delete multiple vaults
- [ ] Reveal multiple secrets
- [ ] **Expected**: Memory stays reasonable (< 100MB for typical use)
- [ ] **Expected**: No memory leaks

### Battery Usage
- [ ] Use app for 30 minutes
- [ ] Check battery usage in Settings
- [ ] **Expected**: Not in top battery consumers
- [ ] **Expected**: Background sync doesn't drain battery

## Phase 9: Security Audit

### Encrypted Storage
- [ ] Use database browser to inspect SQLite file
- [ ] **Expected**: Secrets stored as encrypted blobs (not readable)
- [ ] **Expected**: Vault keys NOT in database plaintext
- [ ] **Expected**: Nonces present for each encrypted field

### Keychain Storage
- [ ] Use Keychain Access or developer tools
- [ ] **Expected**: Vault keys in Keychain with proper access control
- [ ] **Expected**: Private keys in Keychain
- [ ] **Expected**: kSecAttrAccessibleAfterFirstUnlock set

### CloudKit Records
- [ ] Open CloudKit Dashboard
- [ ] Navigate to shared vault
- [ ] **Expected**: Vault record has ownerPublicKey (public is OK)
- [ ] **Expected**: Vault key NOT in CloudKit plaintext
- [ ] **Expected**: APIKey records have encryptedSecret (ciphertext)
- [ ] **Expected**: WrappedVaultKey records exist for each participant
- [ ] **Expected**: Ephemeral public keys present
- [ ] Try to read shared secret directly
- [ ] **Expected**: Cannot decrypt without private key

### Network Traffic (Optional)
- [ ] Use Charles Proxy or similar
- [ ] Perform sync operation
- [ ] **Expected**: All traffic over TLS
- [ ] **Expected**: CloudKit API calls encrypted
- [ ] **Expected**: No secrets visible in traffic logs

## Phase 10: Accessibility

### VoiceOver
- [ ] Enable VoiceOver
- [ ] Navigate through vault list
- [ ] **Expected**: All items have labels
- [ ] **Expected**: Buttons have clear action descriptions
- [ ] Create vault
- [ ] **Expected**: All form fields accessible
- [ ] **Expected**: Can complete entire flow

### Dynamic Type
- [ ] Settings > Increase text size to maximum
- [ ] **Expected**: All text scales appropriately
- [ ] **Expected**: No truncation or overlapping
- [ ] **Expected**: Layouts adapt

### Dark Mode
- [ ] Enable Dark Mode
- [ ] **Expected**: All views have dark appearance
- [ ] **Expected**: Text remains readable
- [ ] **Expected**: Icons have correct style

### High Contrast
- [ ] Enable High Contrast
- [ ] **Expected**: UI elements have sufficient contrast
- [ ] **Expected**: Borders and separators visible

## Phase 11: Localization (Future)

_If localization implemented:_
- [ ] Test in different languages
- [ ] **Expected**: All strings translated
- [ ] **Expected**: Layouts adapt to RTL languages
- [ ] **Expected**: Date/time formats localized

## Final Checks

### App Store Preparation
- [ ] App icon present and correct
- [ ] Launch screen configured
- [ ] Privacy policy created (if needed)
- [ ] App Store description written
- [ ] Screenshots captured (all devices)
- [ ] Metadata complete

### Code Quality
- [ ] All compiler warnings addressed
- [ ] No force unwraps in production code
- [ ] No print statements (use proper logging)
- [ ] No TODOs or FIXMEs in critical paths
- [ ] DocC comments for public APIs

### Documentation
- [ ] README.md complete
- [ ] FEATURES.md up to date
- [ ] SHARING_GUIDE.md accurate
- [ ] CLOUDKIT_SETUP.md accurate
- [ ] SYNC_TESTING.md accurate

## Sign-Off

- [ ] All critical tests passing
- [ ] No known crashes
- [ ] Performance acceptable
- [ ] UI polish complete
- [ ] Documentation complete
- [ ] Ready for TestFlight beta
- [ ] Ready for App Store submission

---

## Notes

Use this section to document any issues found during testing:

- **Issue**: [Description]
- **Severity**: Critical / High / Medium / Low
- **Steps to Reproduce**: [Steps]
- **Expected**: [Expected behavior]
- **Actual**: [Actual behavior]
- **Status**: Open / In Progress / Fixed / Won't Fix

---

**Testing Date**: ___________
**Tester**: ___________
**Build**: ___________
**Devices**: ___________
