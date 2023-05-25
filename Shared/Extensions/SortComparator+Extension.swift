//
//  SortComparator+Extension.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 5/25/23.
//

import Foundation


extension SortComparator where Self == String.Comparator {
    public static var normalized: String.Comparator { .normalized }
}
