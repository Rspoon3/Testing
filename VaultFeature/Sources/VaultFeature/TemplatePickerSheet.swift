import SwiftUI
import TestDriveCore

/// Sheet for selecting a credential template.
///
/// Displays available templates for common services like AWS, OAuth, Twitter, etc.
struct TemplatePickerSheet: View {

    @Environment(\.dismiss) private var dismiss
    let onSelect: (SecretTemplate) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(SecretTemplate.allCases) { template in
                    Button {
                        onSelect(template)
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            // Icon
                            Image(systemName: template.iconName)
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .frame(width: 40)

                            // Template info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(template.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if !template.secretLabels.isEmpty {
                                    Text(secretLabelsText(template.secretLabels))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .padding(.top, 2)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func secretLabelsText(_ labels: [String]) -> String {
        if labels.isEmpty {
            return "Custom fields"
        } else if labels.count == 1 {
            return "1 secret: \(labels[0])"
        } else {
            return "\(labels.count) secrets: \(labels.prefix(2).joined(separator: ", "))\(labels.count > 2 ? "..." : "")"
        }
    }
}

#Preview {
    TemplatePickerSheet { template in
        print("Selected: \(template.displayName)")
    }
}
