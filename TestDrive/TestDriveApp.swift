//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import CloudKit
import Dependencies
import SQLiteData
import SwiftUI
import TestDriveHome
import TestDrivePersistence
import TestDriveCore

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    @Dependency(\.defaultSyncEngine) var syncEngine

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let cloudKitShareMetadata = connectionOptions.cloudKitShareMetadata else { return }
        Task {
            do {
                try await syncEngine.acceptShare(metadata: cloudKitShareMetadata)
            } catch {
                // TODO: Show error to user
            }
        }
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task {
            do {
                try await syncEngine.acceptShare(metadata: cloudKitShareMetadata)
            } catch {
                // TODO: Show error to user
            }
        }
    }
}

@main
struct TestDriveApp: App {
    @UIApplicationDelegateAdaptor var delegate: AppDelegate

    @Dependency(\.defaultSyncEngine) var syncEngine
    @State var syncEngineDelegate = TestDriveSyncEngineDelegate()

    init() {
        // Set up dependencies for @FetchAll observation
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
            $0.defaultSyncEngine = try! SyncEngine(
                for: $0.defaultDatabase,
                tables: Credential.self, Vault.self, VaultParticipant.self, WrappedVaultKey.self,
                containerIdentifier: "iCloud.com.rspoon3.TestDrive",
                delegate: syncEngineDelegate
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .alert(
                    "Reset local data?",
                    isPresented: $syncEngineDelegate.isDeleteLocalDataAlertPresented
                ) {
                    Button("Delete local data", role: .destructive) {
                        Task {
                            await withErrorReporting {
                                try await syncEngine.deleteLocalData()
                            }
                        }
                    }
                } message: {
                    Text("""
                        You are no longer logged into iCloud. Would you like \
                        to reset your local data to the defaults? This will \
                        not affect your data in iCloud.
                        """)
                }
        }
    }
}

@MainActor
@Observable
final class TestDriveSyncEngineDelegate: SyncEngineDelegate {
    var isDeleteLocalDataAlertPresented = false

    func syncEngine(
        _ syncEngine: SyncEngine,
        accountChanged changeType: CKSyncEngine.Event.AccountChange.ChangeType
    ) async {
        switch changeType {
        case .signIn:
            break
        case .signOut, .switchAccounts:
            isDeleteLocalDataAlertPresented = true
        @unknown default:
            break
        }
    }
}
