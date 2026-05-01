//
//  OrderItemView.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import SwiftUI

/// View displaying detailed information about a single order item (Level 3).
struct OrderItemView: View {
    private let viewModel: OrderItemViewModel

    // MARK: - Initializer

    /// Creates an order item view.
    /// - Parameter viewModel: The view model managing item details.
    init(viewModel: OrderItemViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        List {
            Section("Purchased By") {
                LabeledContent("Name", value: viewModel.getUserName())
                LabeledContent("Email", value: viewModel.getUserEmail())
                LabeledContent("Shipping Address", value: viewModel.getUserAddress())
            }

            Section("Product Information") {
                LabeledContent("Product Name", value: viewModel.item.productName)
                LabeledContent("Quantity", value: "\(viewModel.item.quantity)")
                LabeledContent("Unit Price", value: viewModel.formattedUnitPrice())
            }

            Section("Pricing") {
                HStack {
                    Text("Total Price")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(viewModel.formattedTotalPrice())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
            }

            Section("Lock & Key Pattern") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This is the deepest navigation level (Level 3)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Notice how the User object is available 3 levels deep in the navigation hierarchy. This demonstrates the power of the locks and keys pattern - the User was passed through the factory chain, ensuring this view can only exist when a user is authenticated.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        OrderItemView(
            viewModel: OrderItemViewModel(
                item: OrderItem(
                    productName: "Wireless Headphones",
                    quantity: 2,
                    price: 79.99
                ),
                user: User(name: "John Doe", email: "john@example.com")
            )
        )
    }
}
