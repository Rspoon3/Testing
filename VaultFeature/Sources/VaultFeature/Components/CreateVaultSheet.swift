import SwiftUI

/// Sheet for creating a new vault.
struct CreateVaultSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIcon = "lock.fill"
    @State private var selectedColor = "#007AFF"
    @State private var isCreating = false
    @State private var errorMessage: String?

    let viewModel: VaultListViewModel

    // MARK: - Body

    var body: some View {
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
            .navigationTitle("New Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createVault()
                    }
                    .disabled(!isValid || isCreating)
                }
            }
        }
    }

    // MARK: - Private Views

    private var nameSection: some View {
        Section("Name") {
            TextField("Vault name", text: $name)
        }
    }

    private var iconSection: some View {
        Section("Icon") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                ForEach(iconOptions, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(selectedIcon == icon ? .blue : .primary)
                            .frame(width: 50, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIcon == icon ? Color.blue.opacity(0.1) : Color.clear)
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
                        selectedColor = color
                    } label: {
                        Circle()
                            .fill(Color(hex: color) ?? .blue)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .strokeBorder(.blue, lineWidth: selectedColor == color ? 3 : 0)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Private Helpers

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func createVault() {
        isCreating = true
        errorMessage = nil

        Task {
            do {
                try await viewModel.createVault(
                    name: name,
                    iconName: selectedIcon,
                    colorHex: selectedColor
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
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

#Preview {
    CreateVaultSheet(
        viewModel: VaultListViewModel(
            vaultManager: VaultManager(
                database: try! DatabaseManager(enableSync: false),
                encryption: EncryptionService(),
                keychain: KeychainService()
            ),
            apiKeyManager: APIKeyManager(
                database: try! DatabaseManager(enableSync: false),
                encryption: EncryptionService(),
                vaultManager: VaultManager(
                    database: try! DatabaseManager(enableSync: false),
                    encryption: EncryptionService(),
                    keychain: KeychainService()
                )
            )
        )
    )
}
