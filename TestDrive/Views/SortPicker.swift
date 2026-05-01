//
//  SortPicker.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/3/25.
//

import SwiftUI

/// A reusable picker component for selecting sort categories.
///
/// This view displays all available sort categories and shows the current sort direction
/// for the selected category. It can be used standalone in forms or embedded within other views.
///
/// ## Example
///
/// ```swift
/// // In a form
/// Form {
///     Section("Sorting") {
///         SortPicker(sortManager: sortManager)
///     }
/// }
///
/// // With custom title
/// SortPicker(sortManager: sortManager, title: "Order By")
/// ```
struct SortPicker<Category: SortCategory>: View {
    let sortManager: SortManager<Category>
    let title: String
    
    /// Creates a sort picker.
    /// - Parameters:
    ///   - sortManager: The sort manager to bind to
    ///   - title: The title for the picker (defaults to "Sort By")
    init(
        sortManager: SortManager<Category>,
        title: String = "Sort By"
    ) {
        self.sortManager = sortManager
        self.title = title
    }
    
    var body: some View {
        Picker(title, selection: sortManager.categoryBinding) {
            ForEach(Category.allCases) { category in
                if category == sortManager.sortOption.category {
                    Label(
                        category.rawValue,
                        systemImage: sortManager.sortOption.direction.symbol
                    )
                    .tag(category)
                } else {
                    Text(category.rawValue)
                        .tag(category)
                }
            }
        }
    }
}
