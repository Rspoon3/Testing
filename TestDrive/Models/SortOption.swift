//
//  SortOption.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/3/25.
//

import Foundation

/// Combines a sort category with a direction to create a complete sort specification.
///
/// This struct represents a single sort option, containing both what to sort by (category)
/// and how to sort it (direction). It automatically conforms to `Codable` for persistence.
///
/// - Parameters:
///   - Category: The type of enum representing sort categories
struct SortOption<Category: SortCategory>: Codable {
    let category: Category
    var direction: SortDirection
    
    /// Creates a new sort option.
    /// - Parameters:
    ///   - category: The category to sort by
    ///   - direction: The direction to sort in (defaults to descending)
    init(category: Category, direction: SortDirection = .descending) {
        self.category = category
        self.direction = direction
    }
}
