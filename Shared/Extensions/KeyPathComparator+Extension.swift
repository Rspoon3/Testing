//
//  KeyPathComparator+Extension.swift
//  Testing
//
//  Created by Richard Witherspoon on 5/25/23.
//

import Foundation

extension KeyPathComparator {
    public init<Value: Comparable>(
        _ keyPath: KeyPath<Compared, Value?>,
        order: SortOrder,
        nilOrder: SortOrder
    ) {
        switch nilOrder {
        case .forward:
            self.init(keyPath, order: order)
        case .reverse:
            self.init(keyPath, comparator: OptionalComparator(), order: order)
        }
    }
    
    public init(_ keyPath: KeyPath<Compared, Bool>, order: SortOrder = .forward) {
        self.init(keyPath, comparator: BoolComparator(order: order), order: order)
    }
    
    private struct BoolComparator: SortComparator {
        var order: SortOrder
        
        func compare(_ lhs: Bool, _ rhs: Bool) -> ComparisonResult {
            switch (lhs, rhs) {
            case (true, false):
                return order == .forward ? .orderedDescending : .orderedAscending
            case (false, true):
                return order == .forward ? .orderedAscending : .orderedDescending
            default:
                return .orderedSame
            }
        }
    }

    private struct OptionalComparator<T:Comparable>: SortComparator {
        var order: SortOrder = .forward

        func compare(_ lhs: T?, _ rhs: T?) -> ComparisonResult {
            switch (lhs, rhs) {
            case (nil, nil):
                return .orderedSame
            case (.some, nil):
                return .orderedAscending
            case (nil, .some):
                return .orderedDescending
            case let (lhs?, rhs?):
                if let lhs = lhs as? String, let rhs = rhs as? String {
                    return lhs.localizedStandardCompare(rhs)
                } else if lhs < rhs {
                    return .orderedAscending
                } else if lhs > rhs {
                    return .orderedDescending
                } else {
                    return .orderedSame
                }
            }
        }
    }
}
