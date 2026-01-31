import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// View for managing secrets within a credential.
///
/// Allows adding, updating, deleting, and reordering secrets with metadata display.
public struct ManageSecretsView: View {

    @State private var viewModel: ManageSecretsViewModel
    @State private var showingAddSheet = false
    @State private var showingUpdateSheet = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initializer

    /// Creates a new manage secrets view.
    ///
    /// - Parameter viewModel: The view model for this view.
    public init(viewModel: ManageSecretsViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            List {
                if viewModel.secrets.isEmpty {
                    emptySection
                } else {
                    currentSecretsSection

                    if viewModel.isLoading {
                        Section {
                            HStack {
                                Spacer()
                                ProgressView("Loading history...")
                                Spacer()
                            }
                            .padding()
                        }
                    } else if !viewModel.allHistory.isEmpty {
                        historySection
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    errorSection(errorMessage)
                }
            }
            .navigationTitle("Manage Secrets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                if !viewModel.secrets.isEmpty && viewModel.secrets.count > 1 {
                    ToolbarItem(placement: .secondaryAction) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSecretSheet(
                    onAdd: { label, value, expiresAt, rotateAt in
                        Task {
                            try? await viewModel.addSecret(
                                label: label,
                                value: value,
                                expiresAt: expiresAt,
                                rotateAt: rotateAt
                            )
                            showingAddSheet = false
                        }
                    }
                )
            }
            .sheet(item: $viewModel.secretBeingUpdated) { secret in
                UpdateSecretSheet(
                    secret: secret,
                    onUpdate: { newValue, reason, expiresAt, rotateAt in
                        Task {
                            try? await viewModel.updateSecret(
                                secret,
                                newValue: newValue,
                                reason: reason,
                                expiresAt: expiresAt,
                                rotateAt: rotateAt
                            )
                            viewModel.secretBeingUpdated = nil
                        }
                    }
                )
            }
            .alert("Delete Secret", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    viewModel.secretToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let secret = viewModel.secretToDelete {
                        deleteSecret(secret)
                    }
                }
            } message: {
                if let secret = viewModel.secretToDelete {
                    Text("Are you sure you want to delete '\(secret.secretLabel)'? This action cannot be undone.")
                }
            }
            .task {
                try? await viewModel.loadSecrets()
            }
        }
    }

    // MARK: - Private Views

    private var emptySection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "key.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("No Secrets Yet")
                    .font(.headline)

                Text("Add secrets to this credential using the + button above.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }

    private var currentSecretsSection: some View {
        Section {
            ForEach(viewModel.secrets) { secret in
                VStack(alignment: .leading, spacing: 12) {
                    // Header with label and status badge
                    HStack {
                        Text(secret.secretLabel)
                            .font(.headline)

                        Spacer()

                        if let badge = viewModel.statusBadge(for: secret) {
                            Text(badge.label)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(badgeColor(badge.color))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: 4) {
                        metadataRow(
                            icon: "calendar",
                            label: "Created",
                            value: viewModel.relativeTime(from: secret.createdAt)
                        )

                        if secret.updatedAt != secret.createdAt {
                            metadataRow(
                                icon: "arrow.clockwise",
                                label: "Updated",
                                value: viewModel.relativeTime(from: secret.updatedAt)
                            )
                        }

                        if let lastUsed = secret.lastUsedAt {
                            metadataRow(
                                icon: "clock",
                                label: "Last Used",
                                value: viewModel.relativeTime(from: lastUsed)
                            )
                        }

                        if secret.copyCount > 0 {
                            metadataRow(
                                icon: "doc.on.doc",
                                label: "Copied",
                                value: "\(secret.copyCount) time\(secret.copyCount == 1 ? "" : "s")"
                            )
                        }

                        if let expiresAt = secret.expiresAt {
                            metadataRow(
                                icon: secret.isExpired ? "exclamationmark.triangle.fill" : "hourglass",
                                label: "Expires",
                                value: viewModel.relativeTime(from: expiresAt),
                                color: secret.isExpired ? .red : .secondary
                            )
                        }

                        if let rotateAt = secret.rotateAt {
                            metadataRow(
                                icon: secret.needsRotation ? "exclamationmark.triangle.fill" : "arrow.triangle.2.circlepath",
                                label: "Rotate",
                                value: viewModel.relativeTime(from: rotateAt),
                                color: secret.needsRotation ? .orange : .secondary
                            )
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // Actions
                    HStack(spacing: 16) {
                        Button {
                            viewModel.secretBeingUpdated = secret
                        } label: {
                            Label("Update", systemImage: "square.and.pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 8)
            }
            .onMove(perform: viewModel.moveSecrets)
            .onDelete { offsets in
                if let index = offsets.first {
                    viewModel.secretToDelete = viewModel.secrets[index]
                    showingDeleteAlert = true
                }
            }
        } header: {
            Text("Current Secrets (\(viewModel.secrets.count))")
        }
    }

    private var historySection: some View {
        Section {
            ForEach(viewModel.allHistory) { historyEntry in
                VStack(alignment: .leading, spacing: 12) {
                    // Header with label and rotation reason
                    HStack {
                        Text(viewModel.getSecretLabel(for: historyEntry))
                            .font(.headline)

                        Spacer()

                        Text(reasonLabel(historyEntry.reason))
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(reasonColor(historyEntry.reason))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: 4) {
                        if let createdAt = viewModel.getParentSecretCreatedDate(for: historyEntry) {
                            metadataRow(
                                icon: "calendar",
                                label: "Created",
                                value: viewModel.relativeTime(from: createdAt)
                            )
                        }

                        metadataRow(
                            icon: "arrow.clockwise",
                            label: "Replaced",
                            value: viewModel.relativeTime(from: historyEntry.replacedAt)
                        )

                        if historyEntry.copyCount > 0 {
                            metadataRow(
                                icon: "doc.on.doc",
                                label: "Copied",
                                value: "\(historyEntry.copyCount) time\(historyEntry.copyCount == 1 ? "" : "s")"
                            )
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // Secret value with visibility toggle
                    HStack(spacing: 8) {
                        if viewModel.historyVisibility[historyEntry.id] == true {
                            Text(viewModel.decryptedHistory[historyEntry.id] ?? "")
                                .font(.body.monospaced())
                                .textSelection(.enabled)
                        } else {
                            Text(String(repeating: "•", count: 32))
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            Task {
                                await viewModel.toggleHistoryVisibility(historyEntry.id)
                            }
                        } label: {
                            Image(systemName: viewModel.historyVisibility[historyEntry.id] == true ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }

                    // Copy action
                    Button {
                        Task {
                            await viewModel.copyHistoricalSecret(historyEntry)
                        }
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("History (\(viewModel.allHistory.count))")
        }
    }

    private func errorSection(_ message: String) -> some View {
        Section {
            Text(message)
                .foregroundStyle(.red)
                .font(.caption)
        }
    }

    private func metadataRow(
        icon: String,
        label: String,
        value: String,
        color: Color = .secondary
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .frame(width: 16)
                .foregroundStyle(color)

            Text(label + ":")
                .foregroundStyle(color)

            Text(value)
                .foregroundStyle(color)
        }
    }

    private func badgeColor(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        case "gray": return .gray
        default: return .secondary
        }
    }

    private func reasonLabel(_ reason: RotationReason) -> String {
        switch reason {
        case .userInitiated: return "User Updated"
        case .rotated: return "Rotated"
        case .expired: return "Expired"
        case .compromised: return "Compromised"
        }
    }

    private func reasonColor(_ reason: RotationReason) -> Color {
        switch reason {
        case .userInitiated: return .blue
        case .rotated: return .green
        case .expired: return .orange
        case .compromised: return .red
        }
    }

    // MARK: - Private Helpers

    private func deleteSecret(_ secret: CredentialSecret) {
        Task {
            try? await viewModel.deleteSecret(secret)
            viewModel.secretToDelete = nil
        }
    }
}

// MARK: - Add Secret Sheet

private struct AddSecretSheet: View {
    @State private var label = ""
    @State private var value = ""
    @State private var enableExpiration = false
    @State private var expiresAt = Date().addingTimeInterval(86400 * 90)
    @State private var enableRotation = false
    @State private var rotateAt = Date().addingTimeInterval(86400 * 90)
    @State private var isValueVisible = false
    @Environment(\.dismiss) private var dismiss

    let onAdd: (String, String, Date?, Date?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Secret Details") {
                    TextField("Label (e.g., API Key, Client ID)", text: $label)
                        .textInputAutocapitalization(.words)

                    HStack(spacing: 8) {
                        if isValueVisible {
                            TextField("Value", text: $value)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Value", text: $value)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }

                        Button {
                            isValueVisible.toggle()
                        } label: {
                            Image(systemName: isValueVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Toggle("Set Expiration Date", isOn: $enableExpiration)

                    if enableExpiration {
                        DatePicker(
                            "Expires At",
                            selection: $expiresAt,
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text("Expiration")
                } footer: {
                    Text("Optionally set when this secret expires.")
                }

                Section {
                    Toggle("Set Rotation Reminder", isOn: $enableRotation)

                    if enableRotation {
                        DatePicker(
                            "Rotate At",
                            selection: $rotateAt,
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text("Rotation")
                } footer: {
                    Text("Optionally set a reminder to rotate this secret.")
                }
            }
            .navigationTitle("Add Secret")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(
                            label,
                            value,
                            enableExpiration ? expiresAt : nil,
                            enableRotation ? rotateAt : nil
                        )
                    }
                    .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Update Secret Sheet

private struct UpdateSecretSheet: View {
    let secret: CredentialSecret
    @State private var value = ""
    @State private var reason: RotationReason = .userInitiated
    @State private var enableExpiration = false
    @State private var expiresAt = Date().addingTimeInterval(86400 * 90)
    @State private var enableRotation = false
    @State private var rotateAt = Date().addingTimeInterval(86400 * 90)
    @State private var isValueVisible = false
    @Environment(\.dismiss) private var dismiss

    let onUpdate: (String, RotationReason, Date?, Date?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("New Value") {
                    HStack(spacing: 8) {
                        if isValueVisible {
                            TextField("Value", text: $value)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Value", text: $value)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }

                        Button {
                            isValueVisible.toggle()
                        } label: {
                            Image(systemName: isValueVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker("Reason", selection: $reason) {
                        Text("User Initiated").tag(RotationReason.userInitiated)
                        Text("Scheduled Rotation").tag(RotationReason.rotated)
                        Text("Expired").tag(RotationReason.expired)
                        Text("Compromised").tag(RotationReason.compromised)
                    }
                }

                Section {
                    Toggle("Set Expiration Date", isOn: $enableExpiration)

                    if enableExpiration {
                        DatePicker(
                            "Expires At",
                            selection: $expiresAt,
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text("Expiration")
                }

                Section {
                    Toggle("Set Rotation Reminder", isOn: $enableRotation)

                    if enableRotation {
                        DatePicker(
                            "Rotate At",
                            selection: $rotateAt,
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text("Rotation")
                }
            }
            .navigationTitle("Update \(secret.secretLabel)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        onUpdate(
                            value,
                            reason,
                            enableExpiration ? expiresAt : nil,
                            enableRotation ? rotateAt : nil
                        )
                    }
                    .disabled(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            // Pre-fill with existing metadata if available
            enableExpiration = secret.expiresAt != nil
            enableRotation = secret.rotateAt != nil
            if let expires = secret.expiresAt {
                expiresAt = expires
            }
            if let rotate = secret.rotateAt {
                rotateAt = rotate
            }
        }
    }
}

