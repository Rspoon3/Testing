//
//  SortCategory.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/3/25.
//

import Foundation

/// A protocol that defines the requirements for sort category enums.
///
/// Conform your enum to this protocol to use it with the sorting framework.
/// The enum must have `String` raw values and conform to `CaseIterable` to provide all available options.
///
/// ## Example
///
/// ```swift
/// enum TaskSort: String, SortCategory {
///     case title = "Title"
///     case dueDate = "Due Date"
///     case priority = "Priority"
/// }
/// ```
protocol SortCategory: RawRepresentable, Identifiable, CaseIterable, Codable, Hashable where RawValue == String, AllCases: RandomAccessCollection {
    var id: Self { get }
}

extension SortCategory {
    var id: Self { self }
}
