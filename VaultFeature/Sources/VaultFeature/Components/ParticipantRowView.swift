import SwiftUI
import TestDriveCore

/// Row view for displaying a vault participant.
struct ParticipantRowView: View {

    let participant: VaultParticipant
    let onUpdatePermission: (SharePermission) -> Void
    let onRemove: () -> Void

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(participant.userID)
                    .font(.headline)

                HStack(spacing: 8) {
                    statusBadge

                    if participant.publicKey != nil {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            if participant.permission != .owner {
                Menu {
                    Button {
                        onUpdatePermission(.readWrite)
                    } label: {
                        Label("Read & Write", systemImage: "pencil")
                    }

                    Button {
                        onUpdatePermission(.readOnly)
                    } label: {
                        Label("Read Only", systemImage: "eye")
                    }

                    Divider()

                    Button(role: .destructive) {
                        onRemove()
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Text(participant.permission.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Owner")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var statusBadge: some View {
        switch participant.acceptanceStatus {
        case .pending:
            Text("Pending")
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.2))
                .foregroundStyle(.orange)
                .clipShape(Capsule())

        case .accepted:
            Text("Active")
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.2))
                .foregroundStyle(.green)
                .clipShape(Capsule())

        case .declined:
            Text("Declined")
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.2))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Extensions

extension SharePermission {
    var displayName: String {
        switch self {
        case .owner:
            return "Owner"
        case .readWrite:
            return "Read & Write"
        case .readOnly:
            return "Read Only"
        }
    }
}

#Preview {
    List {
        ParticipantRowView(
            participant: VaultParticipant(
                vaultID: UUID(),
                userID: "user@example.com",
                publicKey: Data(),
                permission: .owner,
                acceptanceStatus: .accepted
            ),
            onUpdatePermission: { _ in },
            onRemove: {}
        )

        ParticipantRowView(
            participant: VaultParticipant(
                vaultID: UUID(),
                userID: "collaborator@example.com",
                publicKey: Data(),
                permission: .readWrite,
                acceptanceStatus: .accepted
            ),
            onUpdatePermission: { _ in },
            onRemove: {}
        )

        ParticipantRowView(
            participant: VaultParticipant(
                vaultID: UUID(),
                userID: "pending@example.com",
                permission: .readOnly,
                acceptanceStatus: .pending
            ),
            onUpdatePermission: { _ in },
            onRemove: {}
        )
    }
}
