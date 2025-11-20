import SwiftUI
import UIKit

/// A text view that tracks text selection and reports changes.
struct SelectableTextView: UIViewRepresentable {
    let text: String
    let onSelectionChange: (NSRange) -> Void

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: 17)
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectionChange: onSelectionChange)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        let onSelectionChange: (NSRange) -> Void

        init(onSelectionChange: @escaping (NSRange) -> Void) {
            self.onSelectionChange = onSelectionChange
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            onSelectionChange(textView.selectedRange)
        }
    }
}
