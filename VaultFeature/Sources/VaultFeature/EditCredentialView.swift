import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// Sheet for creating or editing a credential with multiple secrets.
public struct EditCredentialView: View {

    @State private var viewModel: EditCredentialViewModel
    @Environment(\.dismiss) private var dismiss

    private let isEditMode: Bool

    // MARK: - Initializer

    /// Creates a new edit credential view.
    ///
    /// - Parameter viewModel: The view model for this view.
    public init(viewModel: EditCredentialViewModel) {
        self.viewModel = viewModel
        self.isEditMode = viewModel.existingCredential != nil
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                if !isEditMode {
                    templateSection
                    secretsSection
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
            .navigationTitle(isEditMode ? "Edit Credential" : "New Credential")
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
            .sheet(isPresented: $viewModel.showingTemplatePicker) {
                TemplatePickerSheet(
                    onSelect: { template in
                        viewModel.applyTemplate(template)
                        viewModel.showingTemplatePicker = false
                    }
                )
            }
        }
    }

    // MARK: - Private Views

    private var basicInfoSection: some View {
        Section("Basic Information") {
            TextField("Label", text: $viewModel.label)
                .textInputAutocapitalization(.words)

            TextField("Website Domain", text: $viewModel.websiteDomain)
                .textContentType(.URL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)

            TextField("Company", text: $viewModel.company)
                .textInputAutocapitalization(.words)
        }
    }

    private var templateSection: some View {
        Section {
            Button {
                viewModel.showingTemplatePicker = true
            } label: {
                Label("Use Template", systemImage: "doc.text.fill")
            }
        } header: {
            Text("Quick Setup")
        } footer: {
            Text("Choose a template to quickly set up common credential types like AWS, OAuth, or Twitter.")
        }
    }

    private var secretsSection: some View {
        Section {
            ForEach($viewModel.secrets) { $secret in
                VStack(alignment: .leading, spacing: 12) {
                    // Secret label
                    TextField("Secret Name (e.g., API Key, Client ID)", text: $secret.label)
                        .font(.subheadline.weight(.medium))
                        .textInputAutocapitalization(.words)

                    // Secret value with visibility toggle
                    HStack(spacing: 8) {
                        if secret.isVisible {
                            TextField("Value", text: $secret.value)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Value", text: $secret.value)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }

                        Button {
                            viewModel.toggleSecretVisibility(secret.id)
                        } label: {
                            Image(systemName: secret.isVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Action buttons
                    HStack(spacing: 16) {
                        Button {
                            viewModel.generateRandomSecretFor(secret.id)
                        } label: {
                            Label("Generate", systemImage: "wand.and.stars")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)

                        Spacer()

                        if viewModel.secrets.count > 1 {
                            Button(role: .destructive) {
                                if let index = viewModel.secrets.firstIndex(where: { $0.id == secret.id }) {
                                    viewModel.removeSecret(at: index)
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .onMove(perform: viewModel.moveSecrets)

            Button {
                viewModel.addSecret()
            } label: {
                Label("Add Secret", systemImage: "plus.circle.fill")
            }
        } header: {
            HStack {
                Text("Secrets")
                Spacer()
                if viewModel.secrets.count > 1 {
                    EditButton()
                        .font(.caption)
                }
            }
        } footer: {
            Text("Each credential can have multiple secrets. For example, AWS needs both an Access Key ID and Secret Access Key.")
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
    let akm = CredentialManager(encryption: enc, vaultManager: vm)

    return EditCredentialView(
        viewModel: EditCredentialViewModel(
            vaultID: UUID(),
            credentialManager: akm
        )
    )
}
