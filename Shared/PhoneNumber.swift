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
    public let areaCode: Int
    
    /// First three digits of a 7-digit phone number
    public let exchange: Int
    
    /// Last four digits of a 7-digit phone number
    public let number: Int
    
    // Static method to format a phone number using the full format (xxx) xxx-xxxx
    public func formatted(_ formatStyle: PhoneNumberFormatStyle = .full) -> String? {
        switch formatStyle.style {
        case .areaCode:
            return String(areaCode)
        case .excludingAreaCode:
            return "\(exchange)-\(number)"
        case .full:
            return "(\(areaCode)) \(exchange)-\(number)"
        }
    }
    
    // MARK: - Initializer
    
    /// Constructor
    /// - Parameters:
    ///   - areaCode: Area code
    ///   - exchange: First three digits of a 7-digit phone number
    ///   - number: Last four digits of a 7-digit phone number
    public init(areaCode: String, exchange: String, number: String) throws {
        let cleanedAreaCode = areaCode.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        let cleanedExchange = exchange.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        let cleanedNumber = number.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        
        guard
            areaCode == cleanedAreaCode,
            cleanedAreaCode.count == 3,
            let cleanedAreaCodeValue = Int(cleanedAreaCode)
        else {
            throw PhoneNumberError.invalidAreaCode
        }
        
        guard
            exchange == cleanedExchange,
            cleanedExchange.count == 3,
            let cleanedExchangeValue = Int(cleanedExchange)
        else {
            throw PhoneNumberError.invalidExchange
        }
        
        guard
            number == cleanedNumber,
            cleanedNumber.count == 4,
            let cleanedNumberValue = Int(cleanedNumber)
        else {
            throw PhoneNumberError.invalidNumber
        }
        
        self.areaCode = cleanedAreaCodeValue
        self.exchange = cleanedExchangeValue
        self.number = cleanedNumberValue
    }
    
    public init(areaCode: Int, exchange: Int, number: Int) throws {
        try self.init(
            areaCode: String(areaCode),
            exchange: String(exchange),
            number: String(number)
        )
    }
    
    public init(_ input: String) throws {
        let areaCode = String(input.prefix(3))
        let exchange = String(input.dropFirst(3).prefix(3))
        let number = String(input.dropFirst(6).prefix(4))
        
        try self.init(
            areaCode: String(areaCode),
            exchange: String(exchange),
            number: String(number)
        )
    }
    
    public init(_ input: Int) throws {
        try self.init(String(input))
    }
}
