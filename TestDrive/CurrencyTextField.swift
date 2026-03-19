//
//  CurrencyTextField.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 3/19/26.
//

import SwiftUI

/// A text field that accepts numeric input and formats it as currency.
///
/// Shows the currency symbol while typing (e.g. `$25`) and formats
/// as full currency (e.g. `$25.00`) when editing ends.
///
/// - Parameter value: A binding to an optional `Double`.
struct CurrencyTextField: View {
    @Binding private var value: Double?
    private let placeholder: String
    private let currencyCode: String

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    // MARK: - Initializer

    /// Creates a new `CurrencyTextField`.
    /// - Parameters:
    ///   - placeholder: The placeholder text shown when the field is empty.
    ///   - value: A binding to an optional `Double`.
    ///   - currencyCode: The ISO 4217 currency code. Defaults to the device locale.
    init(
        _ placeholder: String = "$0",
        value: Binding<Double?>,
        currencyCode: String? = nil
    ) {
        self._value = value
        self.placeholder = placeholder
        self.currencyCode = currencyCode ?? Locale.current.currency?.identifier ?? "USD"
    }

    // MARK: - Body

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .onChange(of: text) { _, newValue in
                guard isFocused else { return }
                let digits = newValue.filter { $0.isNumber || $0 == "." }
                if digits.isEmpty {
                    text = ""
                } else {
                    text = currencySymbol + digits
                }
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    commitValue()
                }
            }
    }

    // MARK: - Private Helpers

    /// The locale's currency symbol (e.g. "$").
    private var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }

    /// Converts a `Double` to a clean string, dropping `.0` for whole numbers.
    /// - Parameter number: The number to convert.
    /// - Returns: A string representation without trailing `.0`.
    private func rawString(from number: Double) -> String {
        number.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(number))
            : String(number)
    }

    /// Parses the text into a number, updates the binding, and formats as currency.
    private func commitValue() {
        let digits = text.filter { $0.isNumber || $0 == "." }
        let parsed = Double(digits) ?? 0

        if parsed > 0 {
            value = parsed
            let decimal = Decimal(parsed)
            text = decimal.formatted(.currency(code: currencyCode))
        } else {
            value = nil
            text = ""
        }
    }
}

#Preview {
    @Previewable @State var amount: Double?

    VStack(spacing: 20) {
        CurrencyTextField("$100", value: $amount)
            .font(.largeTitle)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)

        Text("Value: \(amount.map { String($0) } ?? "nil")")
            .foregroundStyle(.secondary)
    }
    .padding()
}
