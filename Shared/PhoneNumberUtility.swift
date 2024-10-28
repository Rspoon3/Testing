//
//  PhoneNumberUtility.swift
//  Testing
//
//  Created by Ricky on 10/28/24.
//

import Foundation
import RegexBuilder

public enum PhoneNumberError: Error {
    case invalidAreaCode
    case invalidExchange
    case invalidNumber
}

struct PhoneNumberUtility {
    
    // MARK: - Formatting
    
    public func format(_ input: String) -> String? {
        let formatter = PhoneNumberFormatStyle(.full)
        return formatter.format(input)
    }
}
