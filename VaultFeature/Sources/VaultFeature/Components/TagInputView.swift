import SwiftUI

/// View for adding and managing tags.
struct TagInputView: View {

    @Binding var tags: [String]
    let onAdd: (String) -> Void
    let onRemove: (String) -> Void

    @State private var newTag = ""

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Add tag", text: $newTag)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit {
                        addTag()
                    }

                Button {
                    addTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if !tags.isEmpty {
                tagList
            }
        }
    }

    // MARK: - Private Views

    private var tagList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    tagChip(tag)
                }
            }
        }
    }

    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)

            Button {
                onRemove(tag)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.2))
        .foregroundStyle(.secondary)
        .clipShape(Capsule())
    }

    // MARK: - Private Helpers

    private func addTag() {
        onAdd(newTag)
        newTag = ""
    }
}

#Preview {
    @Previewable @State var tags = ["api", "production", "important"]

    List {
        Section("Tags") {
            TagInputView(
                tags: $tags,
                onAdd: { tags.append($0) },
                onRemove: { tag in tags.removeAll { $0 == tag } }
            )
        }
    }
}
