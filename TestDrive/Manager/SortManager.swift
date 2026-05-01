//
//  SortManager.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/3/25.
//

import SwiftUI

/// Manages sort state with automatic persistence and SwiftUI integration.
///
/// This observable class handles the current sort option, persists it to `UserDefaults`,
/// and provides a binding for use with SwiftUI pickers. It automatically handles the
/// toggle behavior when the same category is selected twice.
///
/// ## Example
///
/// ```swift
/// @State private var sortManager = SortManager<HistorySortCategory>(
///     storageKey: "historySortOption",
///     defaultCategory: .date
/// )
///
/// // Access current sort
/// let currentCategory = sortManager.sortOption.category
/// let currentDirection = sortManager.sortOption.direction
/// ```
@Observable
final class SortManager<Category: SortCategory> {
    private let storageKey: String
    private let defaultCategory: Category
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let userDefaults: UserDefaults
    
    var sortOption: SortOption<Category> {
        didSet {
            save()
        }
    }
    
    /// A binding that provides the category selection behavior for pickers.
    ///
    /// When the same category is selected, it toggles the sort direction.
    /// When a different category is selected, it switches to that category with descending direction.
    var categoryBinding: Binding<Category> {
        Binding(
            get: { self.sortOption.category },
            set: { newCategory in
                if newCategory == self.sortOption.category {
                    self.sortOption.direction.toggle()
                } else {
                    self.sortOption = SortOption(category: newCategory, direction: .descending)
                }
            }
        )
    }
    
    // MARK: - Initializer
    
    /// Creates a new sort manager.
    /// - Parameters:
    ///   - storageKey: The key to use for UserDefaults persistence
    ///   - defaultCategory: The category to use when no saved option exists
    ///   - userDefaults: The `UserDefaults` thats used for persistence
    init(
        storageKey: String,
        defaultCategory: Category,
        userDefaults: UserDefaults = .standard
    ) {
        self.storageKey = storageKey
        self.defaultCategory = defaultCategory
        self.userDefaults = userDefaults
                
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? decoder.decode(SortOption<Category>.self, from: data) {
            self.sortOption = decoded
        } else {
            self.sortOption = SortOption(category: defaultCategory, direction: .descending)
        }
    }
    
    // MARK: - Private
    
    private func save() {
        guard let encoded = try? encoder.encode(sortOption) else { return }
        userDefaults.set(encoded, forKey: storageKey)
    }
}
