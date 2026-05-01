//
//  Color+Hex.swift
//  Testing
//
//  Created by Ricky on 3/3/25.
//

import SwiftUI

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        
        guard hexSanitized.count == 6,
              let rgbValue = UInt64(hexSanitized, radix: 16) else {
            return nil
        }
        
        let red = Double((rgbValue >> 16) & 0xFF) / 255.0
        let green = Double((rgbValue >> 8) & 0xFF) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0
        
        self = Color(red: red, green: green, blue: blue)
    }
}
