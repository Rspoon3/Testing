//
//  StringCurrencyView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 3/19/26.
//

import SwiftUI

/// A demo view using the reusable `CurrencyTextField`.
struct StringCurrencyView: View {
    @State private var amount: Double?
    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            CurrencyTextField("$100", value: $amount)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
//                .focused($isFocused)
            
            CurrencyTextField("$100", value: $amount)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
//                .focused($isFocused)
//            
//                .toolbar {
//                    ToolbarItemGroup(placement: .keyboard) {
//                        Spacer()
//                        Button("Done") {
//                            isFocused = false
//                        }
//                    }
//                }

            Text("Value: \(amount.map { String($0) } ?? "nil")")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    StringCurrencyView()
}
