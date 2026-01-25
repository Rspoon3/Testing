import SwiftUI

/// A text field for secure input with show/hide toggle.
struct SecureTextFieldView: View {

    @Binding var text: String
    @Binding var isVisible: Bool
    let placeholder: String

    // MARK: - Body

    var body: some View {
        HStack {
            if isVisible {
                TextField(placeholder, text: $text)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
            } else {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
            }

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    @Previewable @State var text = "secret-key-123"
    @Previewable @State var isVisible = false

    List {
        Section("Hidden") {
            SecureTextFieldView(
                text: $text,
                isVisible: $isVisible,
                placeholder: "API Key"
            )
        }
    }
}
