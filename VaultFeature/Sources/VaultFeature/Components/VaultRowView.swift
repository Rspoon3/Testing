import SwiftUI
import TestDriveCore

/// Row view for displaying a vault in a list.
struct VaultRowView: View {

    let vault: Vault
    let keyCount: Int

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            vaultIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(vault.name)
                    .font(.headline)

                Text("\(keyCount) \(keyCount == 1 ? "key" : "keys")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if vault.isShared {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Private Views

    private var vaultIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: vault.colorHex) ?? .blue)
                .frame(width: 40, height: 40)

            Image(systemName: vault.iconName)
                .foregroundStyle(.white)
                .font(.system(size: 18))
        }
    }
}

// MARK: - Color Extension

extension Color {

    /// Creates a color from a hex string.
    ///
    /// - Parameter hex: Hex color string (e.g., "#FF0000" or "FF0000").
    /// - Returns: A Color instance, or nil if parsing fails.
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    List {
        VaultRowView(
            vault: Vault(
                name: "Work APIs",
                iconName: "briefcase.fill",
                colorHex: "#007AFF",
                ownerPublicKey: Data()
            ),
            keyCount: 5
        )

        VaultRowView(
            vault: Vault(
                name: "Personal",
                iconName: "person.fill",
                colorHex: "#34C759",
                ownerPublicKey: Data(),
                isShared: true
            ),
            keyCount: 12
        )
    }
}
