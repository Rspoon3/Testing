//
//  PhoneNumberFormatStyle.swift
//  Testing
//
//  Created by Ricky on 10/28/24.
//


import Foundation
import RegexBuilder

// Define different format styles for PhoneNumber
public struct PhoneNumberFormatStyle: FormatStyle, Codable {
    
    public enum Style: String, Codable {
        case areaCode
        case excludingAreaCode
        case full
    }
    
    public var style: Style
    
    public init(_ style: Style) {
        self.style = style
    }
    
    // Implement the format method based on the chosen style
    public func format(_ value: String) -> String? {
        let cleanedInput = value.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        
        // Using RegexBuilder to create more readable and safe patterns
        let fullPhonePattern = Regex {
            Capture {
                Repeat(.digit, count: 3)
            }
            Optionally {
                Capture {
                    Repeat(.digit, 1...3)
                }
            }
            Optionally {
                Capture {
                    Repeat(.digit, 1...4)
                }
            }
        }
        
        switch style {
        case .areaCode:
            guard let match = try? fullPhonePattern.firstMatch(in: cleanedInput) else {
                return value
            }

            return String(match.1)
        case .excludingAreaCode:
            // Excluding area code xxx-xxxx
            guard let match = try? fullPhonePattern.firstMatch(in: cleanedInput) else {
                return nil
            }
            
            guard let exchange = match.2, !exchange.isEmpty else { return nil }
            
            if let lineNumber = match.3, !lineNumber.isEmpty {
                return "\(exchange)-\(lineNumber)"
            } else {
                return String(exchange)
            }
        case .full:
            // Full phone number (xxx) xxx-xxxx
            guard let match = try? fullPhonePattern.firstMatch(in: cleanedInput) else {
                // Return the cleaned input if it's too short for formatting
                return cleanedInput
            }
            
            let areaCode = match.1
            
            if let exchange = match.2, !exchange.isEmpty {
                if let lineNumber = match.3, !lineNumber.isEmpty {
                    return "(\(areaCode)) \(exchange)-\(lineNumber)"
                } else {
                    return "(\(areaCode)) \(exchange)"
                }
            } else {
                return "(\(areaCode))"
            }
        }
    }
    
    // Implement the required Encodable and Decodable conformance
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(style.rawValue)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let styleString = try container.decode(String.self)
        if let style = Style(rawValue: styleString) {
            self.style = style
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid format style")
        }
    }
}

// Extension to support `.areaCode()` and `.full()` format styles
extension FormatStyle where Self == PhoneNumberFormatStyle {
    public static func phoneNumber(_ style: PhoneNumberFormatStyle.Style) -> PhoneNumberFormatStyle {
        PhoneNumberFormatStyle(style)
    }
}
