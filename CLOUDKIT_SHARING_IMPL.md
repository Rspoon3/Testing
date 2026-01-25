# CloudKit Sharing Implementation Guide

This document provides the actual code needed to integrate UICloudSharingController for vault sharing.

## UICloudSharingController Integration

### Step 1: Create Share Controller Coordinator

Create a UIViewControllerRepresentable wrapper for UICloudSharingController.

```swift
// In VaultFeature/Sources/VaultFeature/CloudSharingController.swift

import SwiftUI
import CloudKit

struct CloudSharingController: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowPublic, .allowPrivate, .allowReadOnly, .allowReadWrite]
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            print("Failed to save share: \(error)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "API Key Vault"
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            onDismiss()
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            onDismiss()
        }
    }
}
```

### Step 2: Update VaultManager with Real CloudKit Sharing

Replace the placeholder `shareVault` method:

```swift
// In TestDrivePersistence/Sources/TestDrivePersistence/VaultManager.swift

import CloudKit

public func shareVault(_ vault: Vault) async throws -> CKShare {
    // Get the vault's CKRecord
    guard let ckRecordID = vault.ckRecordID else {
        throw VaultManagerError.noCloudKitRecord
    }

    let recordID = CKRecord.ID(recordName: ckRecordID)
    let container = CKContainer(identifier: "iCloud.com.rspoon3.TestDrive")
    let database = container.privateCloudDatabase

    // Fetch the record
    let record = try await database.record(for: recordID)

    // Create a CKShare
    let share = CKShare(rootRecord: record)
    share[CKShare.SystemFieldKey.title] = vault.name as CKRecordValue
    share.publicPermission = .none // Private sharing only

    // Save the share
    let (savedRecords, _) = try await database.modifyRecords(
        saving: [record, share],
        deleting: []
    )

    guard let savedShare = savedRecords.first(where: { $0 is CKShare }) as? CKShare else {
        throw VaultManagerError.shareCreationFailed
    }

    return savedShare
}
```

### Step 3: Update ShareVaultView to Present Share Sheet

```swift
// In VaultFeature/Sources/VaultFeature/ShareVaultView.swift

@State private var shareToPresent: CKShare?
@State private var showingCloudSharing = false

// Update shareVault() method:
private func shareVault() {
    Task {
        do {
            let share = try await viewModel.shareVault()
            shareToPresent = share
            showingCloudSharing = true
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

// Add to body:
var body: some View {
    NavigationStack {
        List {
            // ... existing sections
        }
        // ... existing modifiers
        .sheet(isPresented: $showingCloudSharing) {
            if let share = shareToPresent {
                CloudSharingController(
                    share: share,
                    container: CKContainer(identifier: "iCloud.com.rspoon3.TestDrive"),
                    onDismiss: {
                        showingCloudSharing = false
                        Task {
                            await viewModel.loadParticipants()
                        }
                    }
                )
            }
        }
    }
}
```

### Step 4: Handle Share Acceptance

Add to TestDriveApp.swift:

```swift
import SwiftUI
import CloudKit

@main
struct TestDriveApp: App {
    @State private var acceptedShare: CKShareMetadata?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    // Handle share acceptance
                    guard let incomingURL = userActivity.webpageURL else { return }

                    CKContainer.default().accept(incomingURL) { metadata, error in
                        if let error = error {
                            print("Failed to accept share: \(error)")
                            return
                        }

                        if let metadata = metadata {
                            acceptedShare = metadata
                            handleAcceptedShare(metadata)
                        }
                    }
                }
        }
    }

    private func handleAcceptedShare(_ metadata: CKShareMetadata) {
        Task {
            do {
                // Extract vault information from share
                guard let rootRecordID = metadata.rootRecordID else { return }

                let container = metadata.containerIdentifier.isEmpty
                    ? CKContainer.default()
                    : CKContainer(identifier: metadata.containerIdentifier)

                let database = container.sharedCloudDatabase

                // Fetch the shared vault record
                let record = try await database.record(for: rootRecordID)

                // Extract vault ID
                guard let vaultIDString = record["id"] as? String,
                      let vaultID = UUID(uuidString: vaultIDString) else {
                    return
                }

                // Get services
                let db = try DatabaseManager()
                let enc = EncryptionService()
                let key = KeychainService()
                let vm = VaultManager(database: db, encryption: enc, keychain: key)

                // Call share acceptance handler
                let userID = metadata.ownerIdentity.userRecordID?.recordName ?? ""
                try await vm.onShareAccepted(
                    vault: /* fetch vault from database */,
                    recipientUserID: userID
                )

            } catch {
                print("Failed to handle accepted share: \(error)")
            }
        }
    }
}
```

### Step 5: Monitor for New Participants

Add background task to monitor participants:

```swift
// In VaultManager.swift

public func startMonitoringShares() async {
    // Set up CKDatabase notification subscription
    let container = CKContainer(identifier: "iCloud.com.rspoon3.TestDrive")
    let database = container.privateCloudDatabase

    // Create subscription for VaultParticipant changes
    let predicate = NSPredicate(value: true)
    let subscription = CKQuerySubscription(
        recordType: "VaultParticipant",
        predicate: predicate,
        options: [.firesOnRecordCreation, .firesOnRecordUpdate]
    )

    let notificationInfo = CKSubscription.NotificationInfo()
    notificationInfo.shouldSendContentAvailable = true
    subscription.notificationInfo = notificationInfo

    do {
        _ = try await database.save(subscription)
        print("Started monitoring for participant changes")
    } catch {
        print("Failed to create subscription: \(error)")
    }
}

// Handle notification in AppDelegate:
func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
) {
    // Parse CKNotification
    let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)

    if let queryNotification = notification as? CKQueryNotification {
        // New participant or participant updated
        Task {
            // Fetch participant details
            // Check if needs key wrapping
            // Wrap key if needed
            completionHandler(.newData)
        }
    }
}
```

## Automatic Key Wrapping

### Background Task for Key Wrapping

```swift
// In VaultManager.swift

private func checkAndWrapKeys(for vault: Vault) async throws {
    // Get all participants
    let participants = try await fetchParticipants(for: vault.id)

    for participant in participants {
        // Skip if not accepted or no public key
        guard participant.acceptanceStatus == .accepted,
              let publicKey = participant.publicKey,
              participant.permission != .owner else {
            continue
        }

        // Check if wrapped key exists
        let hasWrappedKey = try await database.read { db in
            // Query for WrappedVaultKey with:
            // vaultID == vault.id && recipientUserID == participant.userID
            // Return count > 0
            false // Placeholder
        }

        if !hasWrappedKey {
            // Wrap key for this participant
            try await wrapKeyForRecipient(vault: vault, participant: participant)
            print("Wrapped key for participant: \(participant.userID)")
        }
    }
}

// Call this periodically or on participant changes
public func ensureAllKeysWrapped(for vault: Vault) async {
    try? await checkAndWrapKeys(for: vault)
}
```

## Testing the Implementation

### Unit Tests

```swift
import Testing
@testable import TestDrivePersistence

@Suite struct SharingTests {

    @Test func keypairGeneration() async throws {
        let encryption = EncryptionService()

        let privateKey = encryption.generateKeypair()
        let publicKey = encryption.publicKeyData(from: privateKey)

        #expect(publicKey.count == 32)
    }

    @Test func keyAgreement() async throws {
        let encryption = EncryptionService()

        // Generate owner keypair
        let ownerPrivate = encryption.generateKeypair()
        let ownerPublic = try encryption.publicKey(
            from: encryption.publicKeyData(from: ownerPrivate)
        )

        // Generate recipient keypair
        let recipientPrivate = encryption.generateKeypair()
        let recipientPublic = try encryption.publicKey(
            from: encryption.publicKeyData(from: recipientPrivate)
        )

        // Both parties derive same shared secret
        let salt = Data(repeating: 1, count: 32)
        let ownerDerived = try encryption.deriveWrappingKey(
            privateKey: ownerPrivate,
            publicKey: recipientPublic,
            salt: salt
        )
        let recipientDerived = try encryption.deriveWrappingKey(
            privateKey: recipientPrivate,
            publicKey: ownerPublic,
            salt: salt
        )

        #expect(encryption.keyToData(ownerDerived) == encryption.keyToData(recipientDerived))
    }

    @Test func endToEndKeyWrapping() async throws {
        let encryption = EncryptionService()

        // Owner creates vault
        let vaultKey = encryption.generateVaultKey()
        let ownerPrivate = encryption.generateKeypair()

        // Recipient accepts share
        let recipientPrivate = encryption.generateKeypair()
        let recipientPublic = encryption.publicKeyData(from: recipientPrivate)

        // Owner wraps key
        let ephemeralPrivate = encryption.generateKeypair()
        let ephemeralPublic = encryption.publicKeyData(from: ephemeralPrivate)

        let recipientPublicKey = try encryption.publicKey(from: recipientPublic)
        let salt = UUID().uuidString.data(using: .utf8)!

        let wrappingKey = try encryption.deriveWrappingKey(
            privateKey: ephemeralPrivate,
            publicKey: recipientPublicKey,
            salt: salt
        )

        let (wrappedKey, nonce) = try encryption.wrapVaultKey(vaultKey, with: wrappingKey)

        // Recipient unwraps key
        let ephemeralPublicKey = try encryption.publicKey(from: ephemeralPublic)
        let unwrappingKey = try encryption.deriveWrappingKey(
            privateKey: recipientPrivate,
            publicKey: ephemeralPublicKey,
            salt: salt
        )

        let unwrappedKey = try encryption.unwrapVaultKey(
            ciphertext: wrappedKey,
            nonce: nonce,
            wrappingKey: unwrappingKey
        )

        #expect(encryption.keyToData(vaultKey) == encryption.keyToData(unwrappedKey))
    }
}
```

### Integration Test Flow

1. **Create test vault**
2. **Share with test iCloud account**
3. **Accept on second device**
4. **Verify participant record created**
5. **Verify public key synced**
6. **Verify wrapped key created**
7. **Verify recipient can decrypt**

## Debugging

### Enable CloudKit Logging

```swift
// In DatabaseManager.swift
#if DEBUG
let container = CKContainer(identifier: containerIdentifier)
container.accountStatus { status, error in
    print("iCloud status: \(status.rawValue)")
    if let error = error {
        print("iCloud error: \(error)")
    }
}
#endif
```

### Log Key Wrapping

```swift
// In VaultManager.swift
public func wrapKeyForRecipient(vault: Vault, participant: VaultParticipant) async throws {
    print("🔐 Wrapping key for: \(participant.userID)")

    // ... existing code ...

    print("✅ Key wrapped successfully")
    print("   Ciphertext length: \(encryptedVaultKey.count)")
    print("   Ephemeral public key: \(ephemeralPublicData.count) bytes")
}
```

### Monitor CloudKit Dashboard

- Check record counts for each type
- Verify CKShare records created
- Inspect VaultParticipant records
- View WrappedVaultKey records
- Monitor for errors

## Common Issues

### Issue: "Participants not receiving wrapped keys"

**Check:**
1. Participant public key is present
2. VaultParticipant.acceptanceStatus == .accepted
3. Background monitoring is running
4. No CloudKit quota limits hit

### Issue: "Decryption fails on recipient"

**Check:**
1. WrappedVaultKey record synced
2. Recipient private key in Keychain
3. Ephemeral public key matches
4. Salt derivation matches (vaultID)

### Issue: "Share invitation not sent"

**Check:**
1. CKShare record created
2. Email/phone correct in CloudKit
3. Recipient has iCloud account
4. Network connectivity

## Next Steps

After implementing:
1. Test all sharing scenarios
2. Verify encryption at each step
3. Monitor performance
4. Gather user feedback
5. Add audit logging
6. Implement permission UI refinements
