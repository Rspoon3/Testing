//
//  KeyPathComparator+Extension.swift
//  Testing
//
//  Created by Richard Witherspoon on 5/25/23.
//

import Foundation

extension KeyPathComparator {
    public init<Value: Comparable>(forwardOptionalLastUsing keyPath: KeyPath<Compared, Value?>) {
        self.init(keyPath, comparator: OptionalComparator(), order: SortOrder.forward)
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
