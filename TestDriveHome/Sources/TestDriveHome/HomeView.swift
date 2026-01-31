import SwiftUI
import VaultFeature
import SettingsFeature
import TestDrivePersistence

/// Root view coordinating the main tab navigation.
public struct HomeView: View {

    @State private var encryption: EncryptionService
    @State private var keychain: KeychainService
    @State private var vaultManager: VaultManager
    @State private var credentialManager: CredentialManager
    @State private var clipboardManager: ClipboardManager

    // MARK: - Initializer

    /// Creates a new home view.
    public init() {
        let enc = EncryptionService()
        let key = KeychainService()
        let vm = VaultManager(encryption: enc, keychain: key)
        let akm = CredentialManager(encryption: enc, vaultManager: vm)
        let cm = ClipboardManager()

        self.encryption = enc
        self.keychain = key
        self.vaultManager = vm
        self.credentialManager = akm
        self.clipboardManager = cm
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
                credentialManager: credentialManager
            )
        )
        .tabItem {
            Label("Keys", systemImage: "key.fill")
        }
    }

    private var securityTab: some View {
        SecurityWarningsView(
            viewModel: SecurityWarningsViewModel(
                credentialManager: credentialManager,
                clipboardManager: clipboardManager
            )
        )
        .tabItem {
            Label("Security", systemImage: "shield.fill")
        }
    }

    private var settingsTab: some View {
        SettingsView(
            viewModel: SettingsViewModel(
                vaultManager: vaultManager,
                clipboardManager: clipboardManager,
                credentialManager: credentialManager
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
