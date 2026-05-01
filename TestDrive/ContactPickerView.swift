import SwiftUI
import ContactsUI

struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var selectedAddress: String
    var onAddressSelected: (String) -> Void

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            if let postalAddress = contact.postalAddresses.first?.value {
                let formattedAddress = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
                parent.selectedAddress = formattedAddress
                parent.onAddressSelected(formattedAddress) // Pass address back to ContentView
            }
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            print("Contact picker canceled")
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.displayedPropertyKeys = [CNContactPostalAddressesKey] // Only show addresses
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
}
