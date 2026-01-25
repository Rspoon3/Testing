import SwiftUI
import TestDrivePersistence

/// View showing iCloud sync status.
struct SyncStatusView: View {

    let database: DatabaseManager

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            if database.isSyncing {
                ProgressView()
                    .controlSize(.small)
                Text("Syncing...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let error = database.syncError {
                Image(systemName: "exclamationmark.icloud.fill")
                    .foregroundStyle(.orange)
                Text("Sync Error")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let lastSync = database.lastSyncDate {
                Image(systemName: "icloud.fill")
                    .foregroundStyle(.green)
                Text("Synced \(lastSync, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "icloud")
                    .foregroundStyle(.secondary)
                Text("iCloud")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SyncStatusView(
            database: {
                let db = try! DatabaseManager(enableSync: false)
                db.isSyncing = false
                db.lastSyncDate = Date()
                return db
            }()
        )

        SyncStatusView(
            database: {
                let db = try! DatabaseManager(enableSync: false)
                db.isSyncing = true
                return db
            }()
        )

        SyncStatusView(
            database: {
                let db = try! DatabaseManager(enableSync: false)
                db.syncError = NSError(domain: "test", code: -1)
                return db
            }()
        )
    }
    .padding()
}
