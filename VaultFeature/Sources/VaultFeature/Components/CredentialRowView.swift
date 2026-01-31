import SwiftUI
import TestDriveCore

/// Row view for displaying a credential in a list.
struct CredentialRowView: View {

    let key: Credential

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Domain logo
            if let domain = key.websiteDomain {
                DomainLogoView(domain: domain, size: 40)
            } else {
                Image(systemName: "key.fill")
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.secondary)
            }

            // Key info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(key.label)
                        .font(.headline)

                    Spacer()

                    environmentBadge
                }

                if let domain = key.websiteDomain {
                    Text(domain)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !key.tags.isEmpty {
                    tagList
                }

                HStack {
                    if let lastUsed = key.lastUsedAt {
                        Text("Last used: \(lastUsed, format: .relative(presentation: .named))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .transition(.opacity)
                            .id(lastUsed)
                    }

                    Spacer()

                    if let rotateAt = key.rotateAt, rotateAt <= Date() {
                        Label("Needs rotation", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Private Views

    private var environmentBadge: some View {
        Text(key.environment.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(environmentColor.opacity(0.2))
            .foregroundStyle(environmentColor)
            .clipShape(Capsule())
    }

    private var tagList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(key.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var environmentColor: Color {
        switch key.environment {
        case .production:
            return .red
        case .staging:
            return .orange
        case .development:
            return .green
        case .testing:
            return .blue
        case .custom:
            return .purple
        }
    }
}

#Preview {
    List {
        CredentialRowView(
            key: Credential(
                label: "GitHub API Token",
                websiteDomain: "github.com",
                company: "GitHub",
                environment: .production,
                tags: ["git", "vcs", "production"],
                vaultID: UUID()
            )
        )

        CredentialRowView(
            key: Credential(
                label: "Stripe Test Key",
                websiteDomain: "stripe.com",
                environment: .development,
                tags: ["payment"],
                vaultID: UUID()
            )
        )
    }
}
