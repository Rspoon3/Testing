//
//  SortMenu.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/3/25.
//

import SwiftUI

/// A menu component that wraps the sort picker in a dropdown menu.
///
/// This view provides a clean toolbar-friendly interface for sort selection.
/// The menu shows the current sort option and allows users to change categories or toggle direction.
///
/// ## Example
///
/// ```swift
/// // Basic usage
/// .toolbar {
///     ToolbarItem(placement: .primaryAction) {
///         SortMenu(sortManager: sortManager)
///     }
/// }
///
/// // With customization
/// SortMenu(
///     sortManager: sortManager,
///     title: "Order By",
///     menuLabel: "Filter",
///     menuIcon: "line.3.horizontal.decrease.circle"
/// )
/// ```
struct SortMenu<Category: SortCategory>: View {
    private let sortManager: SortManager<Category>
    private let title: String
    private let menuLabel: String
    private let menuIcon: String
    
    /// Creates a sort menu.
    /// - Parameters:
    ///   - sortManager: The sort manager to bind to
    ///   - title: The title for the internal picker (defaults to "Sort By")
    ///   - menuLabel: The label for the menu button (defaults to "Sort By")
    ///   - menuIcon: The SF Symbol for the menu button (defaults to "arrow.up.arrow.down")
    init(
        sortManager: SortManager<Category>,
        title: String = "Sort By",
        menuLabel: String = "Sort By",
        menuIcon: String = "arrow.up.arrow.down"
    ) {
        self.sortManager = sortManager
        self.title = title
        self.menuLabel = menuLabel
        self.menuIcon = menuIcon
    }
    
    var body: some View {
        Menu {
            SortPicker(
                sortManager: sortManager,
                title: title
            )
        } label: {
            Label(
                menuLabel,
                systemImage: menuIcon
            )
        }
    }
}
