//
//  CurrencyView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 3/19/26.
//

import SwiftUI

/// A view with a currency-formatted text field.
struct CurrencyView: View {
    @State private var amount: Decimal = 0
    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            TextField(
                "Enter amount",
                value: Binding(
                    get: {
                        let value = amount > 0 ? amount : nil
                        print("GET: amount = \(amount), returning \(String(describing: value))")
                        return value
                    },
                    set: {
                        print("SET: received \(String(describing: $0))")
                        amount = $0 ?? 0
                    }
                ),
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
    CurrencyView()
}
