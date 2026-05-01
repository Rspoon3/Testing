//
//  OrderHistoryView.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import SwiftUI

/// View displaying a user's order history (Level 1).
struct OrderHistoryView: View {
    private let viewModel: OrderHistoryViewModel

    // MARK: - Initializer

    /// Creates an order history view.
    /// - Parameter viewModel: The view model managing order history.
    init(viewModel: OrderHistoryViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        List(viewModel.orders) { order in
            NavigationLink(value: order) {
                orderRow(for: order)
            }
        }
        .navigationTitle("Order History")
        .navigationDestination(for: Order.self) { order in
            OrderDetailView(viewModel: viewModel.makeOrderDetailViewModel(for: order))
        }
    }

    // MARK: - Private Views

    private func orderRow(for order: Order) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(order.orderNumber)
                    .font(.headline)
                Spacer()
                statusBadge(for: order.status)
            }

            Text(order.date, style: .date)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("$\(order.total, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(for status: OrderStatus) -> some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(for: status).opacity(0.2))
            .foregroundStyle(statusColor(for: status))
            .clipShape(Capsule())
    }

    // MARK: - Private Helpers

    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .pending: .orange
        case .processing: .blue
        case .shipped: .purple
        case .delivered: .green
        case .cancelled: .red
        }
    }
}

#Preview {
    NavigationStack {
        OrderHistoryView(
            viewModel: OrderHistoryViewModel(
                user: User(name: "John Doe", email: "john@example.com")
            )
        )
    }
}
