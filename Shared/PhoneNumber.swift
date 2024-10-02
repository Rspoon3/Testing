//
//  PhoneNumber.swift
//  Testing
//
//  Created by Ricky on 10/1/24.
//

import Foundation

/// Representation of U.S. phone number
public struct PhoneNumber: Codable, Hashable, Sendable {
    
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
    public func formatted(_ formatStyle: PhoneNumberFormatStyle = .full) -> String {
        return formatStyle.format(self)
    }
}


private extension String {
    func digitsOnly() -> String {
        self.filter(\.isWholeNumber)
    }
}

public struct PhoneNumberFormatStyle: ParseableFormatStyle {
    
    public enum Style: String, Codable {
        case areaCode
        case excludingAreaCode
        case full
    }
    
    public var style: Style
    
    public init(_ style: Style) {
        self.style = style
    }
    
    // Parse strategy to convert String to PhoneNumber
    public var parseStrategy: PhoneNumberParseStrategy {
        return PhoneNumberParseStrategy()
    }
    
    // ParseableFormatStyle requires this nested ParseStrategy
    public struct PhoneNumberParseStrategy: ParseStrategy {
        public func parse(_ value: String) throws -> PhoneNumber {
            let cleanedInput = value.digitsOnly()
            
            let areaCode = String(cleanedInput.prefix(3))
            let exchange = String(cleanedInput.dropFirst(3).prefix(3))
            let number = String(cleanedInput.suffix(4))
            return PhoneNumber(areaCode: areaCode, exchange: exchange, number: number)
        }
    }
    
    // Formatting logic (convert PhoneNumber to String)
    public func format(_ value: PhoneNumber) -> String {
        switch style {
        case .areaCode:
            return value.areaCode ?? ""
        case .excludingAreaCode:
            if let exchange = value.exchange, let number = value.number {
                return "\(exchange)-\(number)"
            } else {
                return "Incomplete phone number"
            }
        case .full:
            guard let areaCode = value.areaCode else { return "" }
            guard areaCode.count == 3 else {
                return "\(areaCode)"
            }
            
            if let exchange = value.exchange, !exchange.isEmpty {
                if let number = value.number, !number.isEmpty {
                    return "(\(areaCode)) \(exchange)-\(number)"
                } else {
                    return "(\(areaCode)) \(exchange)"
                }
            } else {
                return "(\(areaCode))"
            }
        }
    }
}

// Extension for ParseableFormatStyle convenience
extension ParseableFormatStyle where Self == PhoneNumberFormatStyle {
    static var phoneNumber: PhoneNumberFormatStyle {
        .full
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



