import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension String {
    /// Binding helper for converting between hex string and SwiftUI Color.
    ///
    /// Allows two-way binding between a String property containing a hex color
    /// (e.g., "#007AFF") and a ColorPicker.
    public var swiftUIColor: Color {
        get {
            Color(hex: self) ?? .blue
        }
        set {
            self = newValue.toHex()
        }
    }
}

extension Color {
    /// Creates a color from a hex string.
    ///
    /// - Parameter hex: Hex color string (e.g., "#FF0000" or "FF0000").
    /// - Returns: A Color instance, or nil if parsing fails.
    public init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    /// Converts a Color to a hex string.
    ///
    /// - Returns: Hex color string with # prefix (e.g., "#007AFF")
    public func toHex() -> String {
        #if canImport(UIKit)
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        return "#000000"
        #endif
    }
}
