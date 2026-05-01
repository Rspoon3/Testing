//
//  StringComparator+Extension.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 5/25/23.
//

import Foundation


extension String.Comparator {
    public static let normalized = String.Comparator(
        options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
        locale: .current
    )
}
