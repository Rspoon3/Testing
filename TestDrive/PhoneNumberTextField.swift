//
//  PhoneNumberTextField.swift
//  TestingTests
//
//  Created by Ricky on 10/28/24.
//

import SwiftUI
import Combine

struct PhoneNumberTextFieldViewModel {
    func clean(using newValue: String) -> String {
        if newValue.contains("(") && !newValue.contains(")") {
            let cleaned = newValue.replacingOccurrences(of: "(", with: "")
            let dropped = String(cleaned.dropLast())
            return dropped.formatted(.phoneNumber(.full)) ?? ""
        } else {
            return newValue.formatted(.phoneNumber(.full)) ?? ""
        }
    }
}

struct PhoneNumberTextField: View {
    private let viewModel = PhoneNumberTextFieldViewModel()
    let placeholder: String
    @Binding var text: String
    
    init(
        _ placeholder: String,
        text: Binding<String>
    ) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        TextField(placeholder, text: $text)
            .onReceive(Just(text)) { value in
                text = viewModel.clean(using: value)
            }
    }
}

#Preview {
    PhoneNumberTextField(
        "Phone Number",
        text: .constant("123")
    )
}
