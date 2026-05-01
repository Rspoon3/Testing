import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", 
                      lroundf(r * 255), 
                      lroundf(g * 255), 
                      lroundf(b * 255))
    }
}

struct ThemeColors {
    static let sunsetPalette = [
        Color(hex: "#FFB6A3"),
        Color(hex: "#FFC4A3"),
        Color(hex: "#FFD4A3"),
        Color(hex: "#FFE4B5"),
        Color(hex: "#FFDAB9"),
        Color(hex: "#F4A460"),
        Color(hex: "#E8B4A5"),
        Color(hex: "#D4A373"),
        Color(hex: "#C19A6B"),
        Color(hex: "#BC9A6A")
    ]
    
    static let earthyPalette = [
        Color(hex: "#8B7355"),
        Color(hex: "#A0896C"),
        Color(hex: "#B5A290"),
        Color(hex: "#CABBA4"),
        Color(hex: "#DFD4B8"),
        Color(hex: "#704214"),
        Color(hex: "#8B4513"),
        Color(hex: "#A0522D"),
        Color(hex: "#CD853F"),
        Color(hex: "#DEB887")
    ]
    
    static let calmingPalette = [
        Color(hex: "#E6D7C9"),
        Color(hex: "#D9C8B4"),
        Color(hex: "#CCB9A0"),
        Color(hex: "#BFAA8C"),
        Color(hex: "#B29B78"),
        Color(hex: "#A58C64"),
        Color(hex: "#987D50"),
        Color(hex: "#8B6E3C"),
        Color(hex: "#7E5F28"),
        Color(hex: "#715014")
    ]
    
    static var allColors: [Color] {
        sunsetPalette + earthyPalette + calmingPalette
    }
}
