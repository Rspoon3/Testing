//
//  PhoneNumber.swift
//  Testing
//
//  Created by Ricky on 10/1/24.
//

import Foundation

/// Representation of U.S. phone number
public struct PhoneNumber: Codable {
    
    /// Area code
    public var areaCode: String?
    
    /// First three digits of a 7-digit phone number
    public var exchange: String?
    
    /// Last four digits of a 7-digit phone number
    public var number: String?
    
    /// Constructor
    /// - Parameters:
    ///   - areaCode: Area code
    ///   - exchange: First three digits of a 7-digit phone number
    ///   - number: Last four digits of a 7-digit phone number
    public init(areaCode: String?, exchange: String?, number: String?) {
        self.areaCode = areaCode?.digitsOnly()
        self.exchange = exchange?.digitsOnly()
        self.number = number?.digitsOnly()
    }
    
    public init(areaCode: Int?, exchange: Int?, number: Int?) {
        if let areaCode {
            self.areaCode = String(areaCode)
        }
        
        if let exchange {
            self.exchange = String(exchange)
        }
        
        if let number {
            self.number = String(number)
        }
    }
    
    public init() {}
    
    public init(_ input: String) {
        let cleanedInput = input.digitsOnly()
        
        areaCode = String(cleanedInput.prefix(3))
        exchange = String(cleanedInput.dropFirst(3).prefix(3))
        number = String(cleanedInput.dropFirst(6).prefix(4))
    }
    
    public init(_ input: Int) {
        self.init(String(input))
    }
    
    // Static method to format a phone number using the full format (xxx) xxx-xxxx
    public func formatted(_ formatStyle: PhoneNumberFormatStyle = .full) -> String? {
        return formatStyle.format(self)
    }
}


private extension String {
    func digitsOnly() -> String {
        self.filter(\.isWholeNumber)
    }
}


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
    public func format(_ value: PhoneNumber) -> String? {
        let full = [value.areaCode, value.exchange, value.number].compactMap{$0}.joined()
        let cleanedInput = full.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        
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
             // Area code xxx
            return value.areaCode
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
    public static var areaCode: PhoneNumberFormatStyle {
        PhoneNumberFormatStyle(.areaCode)
    }
    
    public static var excludingAreaCode: PhoneNumberFormatStyle {
        PhoneNumberFormatStyle(.excludingAreaCode)
    }
    
    public static var full: PhoneNumberFormatStyle {
        PhoneNumberFormatStyle(.full)
    }
}
