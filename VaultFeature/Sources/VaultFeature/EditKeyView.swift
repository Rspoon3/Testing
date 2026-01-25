import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// Sheet for creating or editing an API key.
public struct EditKeyView: View {

    @State private var viewModel: EditKeyViewModel
    @Environment(\.dismiss) private var dismiss

    private let isEditMode: Bool

    // MARK: - Initializer

    /// Creates a new edit key view.
    ///
    /// - Parameter viewModel: The view model for this view.
    public init(viewModel: EditKeyViewModel) {
        self.viewModel = viewModel
        self.isEditMode = viewModel.existingKey != nil
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                if !isEditMode {
                    secretSection
                }
                classificationSection
                metadataSection

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Key" : "New API Key")
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
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
        }
    }

    // MARK: - Private Views

    private var basicInfoSection: some View {
        Section("Basic Information") {
            TextField("Label", text: $viewModel.label)

            TextField("Website Domain", text: $viewModel.websiteDomain)
                .textContentType(.URL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)

            TextField("Company", text: $viewModel.company)
        }
    }

    private var secretSection: some View {
        Section {
            SecureTextFieldView(
                text: $viewModel.secret,
                isVisible: $viewModel.isSecretVisible,
                placeholder: "API Key Secret"
            )

            Button {
                viewModel.secret = viewModel.generateRandomSecret()
            } label: {
                Label("Generate Random Key", systemImage: "wand.and.stars")
            }
        } header: {
            Text("Secret")
        } footer: {
            Text("The secret will be encrypted and stored securely.")
        }
    }

    private var classificationSection: some View {
        Section("Classification") {
            Picker("Environment", selection: $viewModel.environment) {
                ForEach(APIEnvironment.allCases, id: \.self) { env in
                    Text(env.rawValue.capitalized).tag(env)
                }
            }

            TagInputView(
                tags: $viewModel.tags,
                onAdd: viewModel.addTag,
                onRemove: viewModel.removeTag
            )
        }
    }

    private var metadataSection: some View {
        Section("Additional Information") {
            TextField("Notes", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)

            Toggle("Rotation Reminder", isOn: $viewModel.enableRotationReminder)

            if viewModel.enableRotationReminder {
                DatePicker(
                    "Rotate At",
                    selection: Binding(
                        get: { viewModel.rotateAt ?? Date().addingTimeInterval(86400 * 90) },
                        set: { viewModel.rotateAt = $0 }
                    ),
                    displayedComponents: .date
                )
            }
        }
    }

    // MARK: - Private Helpers

    private func save() {
        Task {
            do {
                try await viewModel.save()
                dismiss()
            } catch {
                // Error is handled in view model
            }
        }
    }
}

#Preview {
    setupPreviewDependencies()

    let enc = EncryptionService()
    let key = KeychainService()
    let vm = VaultManager(encryption: enc, keychain: key)
    let akm = APIKeyManager(encryption: enc, vaultManager: vm)

    return EditKeyView(
        viewModel: EditKeyViewModel(
            vaultID: UUID(),
            apiKeyManager: akm
        )
    )
}
