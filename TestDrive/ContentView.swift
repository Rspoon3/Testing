//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

// Example usage:
enum HistorySortCategory: String, SortCategory {
    case title = "Title"
    case date = "Date"
    case messagesSent = "Messages Sent"
}

// Usage in another view with different categories:
enum ProductSortCategory: String, SortCategory {
    case name = "Name"
    case price = "Price"
    case rating = "Rating"
}

struct ContentView: View {
    @State private var sortManager = SortManager<HistorySortCategory>(
        storageKey: "historySortOption",
        defaultCategory: .date
    )

    var body: some View {
        NavigationStack {
            Form {
                // Your content here
                // Access current sort with: sortManager.sortOption
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    SortMenu(sortManager: sortManager)
                }
            }
        }
    }
}

struct ProductListView: View {
    private let sortManager = SortManager<ProductSortCategory>(
        storageKey: "productSortOption",
        defaultCategory: .name
    )

    var body: some View {
        NavigationStack {
            List {
                // Your products here
                // Access current sort with: sortManager.sortOption
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    SortMenu(sortManager: sortManager)
                }
            }
        }
    }
}
