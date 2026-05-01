//
//  SortDirection.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/3/25.
//

import Foundation

/// Represents the direction of a sort operation.
///
/// Use this enum to specify whether items should be sorted in ascending or descending order.
/// The enum provides convenient methods for toggling direction and accessing appropriate SF Symbols.
enum SortDirection: Codable {
    case ascending, descending
    
    /// The SF Symbol name representing this sort direction.
    ///
    /// Returns `"chevron.up"` for ascending and `"chevron.down"` for descending.
    var symbol: String {
        switch self {
        case .ascending: return "chevron.up"
        case .descending: return "chevron.down"
        }
    }
    
    /// Toggles the sort direction.
    ///
    /// Changes ascending to descending and vice versa.
    mutating func toggle() {
        switch self {
        case .ascending: self = .descending
        case .descending: self = .ascending
        }
    }
}
