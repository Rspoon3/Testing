import SwiftUI
import VaultFeature
import SettingsFeature
import TestDrivePersistence

/// Root view coordinating the main tab navigation.
public struct HomeView: View {

    @State private var database: DatabaseManager
    @State private var encryption: EncryptionService
    @State private var keychain: KeychainService
    @State private var vaultManager: VaultManager
    @State private var apiKeyManager: APIKeyManager
    @State private var clipboardManager: ClipboardManager

    // MARK: - Initializer

    /// Creates a new home view.
    public init() {
        do {
            let db = try DatabaseManager()
            let enc = EncryptionService()
            let key = KeychainService()
            let vm = VaultManager(database: db, encryption: enc, keychain: key)
            let akm = APIKeyManager(database: db, encryption: enc, vaultManager: vm)
            let cm = ClipboardManager()

            self.database = db
            self.encryption = enc
            self.keychain = key
            self.vaultManager = vm
            self.apiKeyManager = akm
            self.clipboardManager = cm
        } catch {
            fatalError("Failed to initialize services: \(error)")
        }
    }

    // MARK: - Body

    public var body: some View {
        TabView {
            keysTab
            securityTab
            settingsTab
        }
    }

    // MARK: - Private Views

    private var keysTab: some View {
        VaultListView(
            viewModel: VaultListViewModel(
                vaultManager: vaultManager,
                apiKeyManager: apiKeyManager,
                database: database
            )
        )
        .tabItem {
            Label("Keys", systemImage: "key.fill")
        }
    }

    private var securityTab: some View {
        SecurityWarningsView(
            viewModel: SecurityWarningsViewModel(
                apiKeyManager: apiKeyManager,
                clipboardManager: clipboardManager,
                database: database
            )
        )
        .tabItem {
            Label("Security", systemImage: "shield.fill")
        }
    }

    private var settingsTab: some View {
        SettingsView(
            viewModel: SettingsViewModel(
                database: database,
                vaultManager: vaultManager,
                clipboardManager: clipboardManager
            )
        )
        .tabItem {
            Label("Settings", systemImage: "gear")
        }
    }
}

#Preview {
    HomeView()
}
