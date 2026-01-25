import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// Configuration screen for editing vault settings.
///
/// Uses the Draft pattern to temporarily hold changes until explicitly saved.
public struct VaultConfigurationView: View {

    @State var vault: Vault.Draft
    @Environment(\.dismiss) var dismiss
    @State private var errorMessage: String?

    let vaultManager: VaultManager

    // MARK: - Initializer

    /// Creates a new vault configuration view.
    ///
    /// - Parameters:
    ///   - vault: The vault draft to edit.
    ///   - vaultManager: The vault manager for saving changes.
    public init(vault: Vault.Draft, vaultManager: VaultManager) {
        self.vault = vault
        self.vaultManager = vaultManager
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $vault.name)
                } header: {
                    Text("Vault Name")
                }

                Section {
                    TextField("Icon Name", text: $vault.iconName)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("Icon")
                } footer: {
                    Text("Enter an SF Symbol name (e.g., lock.fill, folder, key.fill)")
                }

                Section {
                    ColorPicker("Color", selection: $vault.colorHex.swiftUIColor)
                } header: {
                    Text("Display Color")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Vault Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func saveChanges() {
        Task {
            do {
                // Convert draft to full Vault object for update
                guard let existingVault = vault.id else {
                    throw VaultConfigurationError.missingID
                }

                // Create updated vault from draft
                let updatedVault = Vault(
                    id: existingVault,
                    name: vault.name,
                    iconName: vault.iconName,
                    colorHex: vault.colorHex,
                    sortOrder: vault.sortOrder,
                    isDefault: vault.isDefault,
                    createdAt: vault.createdAt,
                    updatedAt: Date(),
                    ownerPublicKey: vault.ownerPublicKey,
                    ckRecordID: vault.ckRecordID,
                    ckShareID: vault.ckShareID,
                    isShared: vault.isShared,
                    ownerUserID: vault.ownerUserID
                )

                try await vaultManager.updateVault(updatedVault)
                dismiss()
            } catch {
                errorMessage = "Failed to save changes: \(error.localizedDescription)"
            }
        }
    }
}

enum VaultConfigurationError: Error {
    case missingID
}

#Preview {
    setupPreviewDependencies()

    let enc = EncryptionService()
    let key = KeychainService()
    let vaultManager = VaultManager(encryption: enc, keychain: key)

    let vault = Vault(
        name: "Work Keys",
        iconName: "briefcase.fill",
        colorHex: "#007AFF",
        ownerPublicKey: Data()
    )

    return VaultConfigurationView(vault: Vault.Draft(vault), vaultManager: vaultManager)
}
