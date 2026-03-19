//
//  OptionalCurrencyView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 3/19/26.
//

import SwiftUI

/// A view with a currency text field backed by an optional amount.
struct OptionalCurrencyView: View {
    @State private var amount: Decimal?
    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            TextField(
                "Enter amount",
                value: $amount,
                format: .currency(code: Locale.current.currency?.identifier ?? "USD")
            )
            .font(.largeTitle)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .focused($isFocused)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    OptionalCurrencyView()
}
