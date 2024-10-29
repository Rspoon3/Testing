//
//  PhoneNumberCleaner.swift
//  Testing
//
//  Created by Ricky on 10/28/24.
//

import Foundation

protocol PhoneNumberCleaning {
    func cleanForRealtimeFormatting(using newValue: String) -> String
}

/// An object that manages cleaning a string thats being used in conjunction with `PhoneNumberFormatStyle`
/// to provide "realtime" formatting as the user types.
struct PhoneNumberCleaner {
    func cleanForRealtimeFormatting(using newValue: String) -> String {
        if newValue.contains("(") && !newValue.contains(")") {
            let cleaned = newValue.replacingOccurrences(of: "(", with: "")
            let dropped = String(cleaned.dropLast())
            return dropped.formatted(.phoneNumber(.full)) ?? ""
        } else {
            return newValue.formatted(.phoneNumber(.full)) ?? ""
        }
    }
}
