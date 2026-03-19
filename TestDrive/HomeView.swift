//
//  HomeView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 3/19/26.
//

import SwiftUI

/// A view with a non-optional currency text field.
struct HomeViewd: View {
    @State private var amount: Decimal = 0
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
    HomeView()
}
import SwiftUI

struct HomeView: View {
    
    @State private var value: Double?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            Button("Toggle") {
                isFocused.toggle()
            }

            TextField(
                "$100",
                value: $value,
                format: .currency(code: Locale.current.currency?.identifier ?? "USD")
            )
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
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
    }
}

