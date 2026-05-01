//
//  Color+HexInit.swift
//  FetchHop
//
//  Created by Julio Marquez on 1/27/22.
//  Copyright © 2022 Fetch Rewards, LLC. All rights reserved.
//

import SwiftUI

extension Color {

    /// A `Color` initializer that accepts a hexadecimal string value.
    ///
    /// - Parameters:
    ///   - hex: The hexadecimal string value to be used. This can be in
    ///     the form of a 12-bit (`"#00F"`), 24-bit (`"#00FF00"`),
    ///     or 32-bit (`"#00FF00CC"`) hexadecimal. The hash (#) is optional.
    /// - Returns: A `Color` instance represented by the `hex` argument.
    ///   If the `hex` value is not valid, it will return a `clear` `Color` instance.

    init(hex: String) {
        let hexCharacters = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexCharacters).scanHexInt64(&int)
        let a, r, g, b: UInt64

        switch hexCharacters.count {

        // RGB (12-bit)
        case 3:
            a = 255
            r = (int >> 8) * 17
            g = (int >> 4 & 0xF) * 17
            b = (int & 0xF) * 17

        // RGB (24-bit)
        case 6:
            a = 255
            r = int >> 16
            g = int >> 8 & 0xFF
            b = int & 0xFF

        // ARGB (32-bit)
        case 8:
            a = int >> 24
            r = int >> 16 & 0xFF
            g = int >> 8 & 0xFF
            b = int & 0xFF

        default:
            self = .clear
            return
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
