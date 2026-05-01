//
//  OrderTrackingView.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import SwiftUI

/// View for tracking an order's shipping status.
/// This view can ONLY be created through OrderBoundFactory (requires User AND Order).
struct OrderTrackingView: View {
    private let viewModel: OrderTrackingViewModel

    // MARK: - Initializer

    /// Creates an order tracking view.
    /// - Parameter viewModel: The view model managing tracking data.
    init(viewModel: OrderTrackingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        List {
            Section("Order Information") {
                LabeledContent("Order Number", value: viewModel.getOrderNumber())
                LabeledContent("Tracking Number", value: viewModel.trackingNumber)
            }

            Section("Delivery Information") {
                LabeledContent("Recipient", value: viewModel.getUserName())
                LabeledContent("Shipping Address", value: viewModel.getShippingAddress())
                LabeledContent("Estimated Delivery", value: viewModel.formattedEstimatedDelivery())
            }

            Section("Current Status") {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Location")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(viewModel.currentLocation)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    Image(systemName: "shippingbox.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .padding(.vertical, 4)
            }

            Section("Factory Pattern") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("3-Level Factory Hierarchy")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("This view demonstrates the deepest level of the locks and keys pattern:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        factoryLevelRow(level: "1", name: "RootFactory", creates: "Shared services & UserBoundFactory")
                        factoryLevelRow(level: "2", name: "UserBoundFactory", creates: "User-specific views & OrderBoundFactory")
                        factoryLevelRow(level: "3", name: "OrderBoundFactory", creates: "Order-specific views (this one!)")
                    }
                    .font(.caption2)
                    .padding(.top, 4)

                    Text("This view can ONLY be created when both a User AND an Order are available, enforced at compile-time.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .navigationTitle("Track Order")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh") {
                    Task {
                        await viewModel.refreshTracking()
                    }
                }
            }
        }
    }

    // MARK: - Private Views

    private func factoryLevelRow(level: String, name: String, creates: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(level)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .fontWeight(.semibold)
                Text("→ \(creates)")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        OrderTrackingView(
            viewModel: OrderTrackingViewModel(
                user: User(name: "John Doe", email: "john@example.com"),
                order: Order(
                    orderNumber: "ORD-001",
                    date: Date(),
                    total: 129.99,
                    status: .shipped,
                    items: []
                ),
                apiClient: APIClient()
            )
        )
    }
}
