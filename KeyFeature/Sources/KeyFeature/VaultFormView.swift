import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// Form for creating or editing a vault.
///
/// Uses the Draft pattern to temporarily hold changes until explicitly saved.
/// Handles both creation (draft.id == nil) and editing (draft.id != nil).
public struct VaultFormView: View {

    @State var vault: Vault.Draft
    @Environment(\.dismiss) var dismiss
    @State private var errorMessage: String?
    @State private var isSaving = false

    let vaultManager: VaultManager

    // MARK: - Initializer

    /// Creates a new vault form view.
    ///
    /// - Parameters:
    ///   - vault: The vault draft to create or edit.
    ///   - vaultManager: The vault manager for save operations.
    public init(vault: Vault.Draft, vaultManager: VaultManager) {
        self.vault = vault
        self.vaultManager = vaultManager
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                nameSection
                iconSection
                colorSection

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(vault.id == nil ? "New Vault" : "Edit Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }

    // MARK: - Private Views

    private var nameSection: some View {
        Section("Name") {
            TextField("Vault name", text: $vault.name)
        }
    }

    private var iconSection: some View {
        Section("Icon") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                ForEach(iconOptions, id: \.self) { icon in
                    Button {
                        vault.iconName = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(vault.iconName == icon ? .blue : .primary)
                            .frame(width: 50, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(vault.iconName == icon ? Color.blue.opacity(0.1) : Color.clear)
                            )
                    }
                }
            }
        }
    }

    private var colorSection: some View {
        Section("Color") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                ForEach(colorOptions, id: \.self) { color in
                    Button {
                        vault.colorHex = color
                    } label: {
                        Circle()
                            .fill(Color(hex: color) ?? .blue)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .strokeBorder(.blue, lineWidth: vault.colorHex == color ? 3 : 0)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Private Helpers

    private var isValid: Bool {
        !vault.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                if vault.id == nil {
                    // Create new vault
                    try await vaultManager.createVault(
                        name: vault.name,
                        iconName: vault.iconName,
                        colorHex: vault.colorHex
                    )
                } else {
                    // Update existing vault
                    let updatedVault = Vault(
                        id: vault.id!,
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
                }
                dismiss()
            } catch {
                errorMessage = "Failed to save vault: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }

    private let iconOptions = [
        "lock.fill",
        "briefcase.fill",
        "person.fill",
        "house.fill",
        "server.rack",
        "wrench.and.screwdriver.fill",
        "key.fill",
        "shield.fill",
        "lock.shield.fill",
        "building.2.fill",
        "folder.fill",
        "star.fill"
    ]

    private let colorOptions = [
        "#007AFF", // Blue
        "#34C759", // Green
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Yellow
        "#AF52DE", // Purple
        "#FF2D55", // Pink
        "#5AC8FA", // Teal
        "#8E8E93"  // Gray
    ]
}

#Preview("Create") {
    setupPreviewDependencies()

    let enc = EncryptionService()
    let key = KeychainService()
    let vm = VaultManager(encryption: enc, keychain: key)

    return VaultFormView(
        vault: Vault.Draft(
            name: "",
            iconName: "lock.fill",
            colorHex: "#007AFF",
            ownerPublicKey: Data()
        ),
        vaultManager: vm
    )
}

#Preview("Edit") {
    setupPreviewDependencies()

    let enc = EncryptionService()
    let key = KeychainService()
    let vm = VaultManager(encryption: enc, keychain: key)

    let vault = Vault(
        name: "Work Keys",
        iconName: "briefcase.fill",
        colorHex: "#007AFF",
        ownerPublicKey: Data()
    )

    return VaultFormView(vault: Vault.Draft(vault), vaultManager: vm)
}
