//
//  PhoneNumberFormatStyle.swift
//  Testing
//
//  Created by Ricky on 10/1/24.
//

import RegexBuilder
import Foundation
//
//// Define a custom FormatStyle for formatting phone numbers
//struct PhoneNumberFormatStyle: FormatStyle {
//    // Define the input and output types of the format style
//    typealias FormatInput = String
//    typealias FormatOutput = String
//
//    // Implement the format method that applies the USA phone number format
//    func format(_ value: String) -> String {
//        // Remove all non-digit characters
//        let cleanedInput = value.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
//        
//        // Using RegexBuilder to create more readable and safe patterns
//        let fullPhonePattern = Regex {
//            Capture {
//                Repeat(.digit, count: 3)
//            }
//            Optionally {
//                Capture {
//                    Repeat(.digit, 1...3)
//                }
//            }
//            Optionally {
//                Capture {
//                    Repeat(.digit, 1...4)
//                }
//            }
//        }
//        
//        // Full phone number (xxx) xxx-xxxx
//        guard let match = try? fullPhonePattern.firstMatch(in: cleanedInput) else {
//            // Return the cleaned input if it's too short for formatting
//            return cleanedInput
//        }
//        
//        let areaCode = match.1
//        let exchange = match.2
//        let lineNumber = match.3
//        
//        if let exchange, !exchange.isEmpty {
//            if let lineNumber, !lineNumber.isEmpty {
//                return "(\(areaCode)) \(exchange)-\(lineNumber)"
//            } else {
//                return "(\(areaCode)) \(exchange)"
//            }
//        } else {
//            return "(\(areaCode))"
//        }
//    }
//}
//
//// Extend String so that it can easily use the custom PhoneNumberFormatStyle
//extension FormatStyle where Self == PhoneNumberFormatStyle {
//    static var phoneNumber: PhoneNumberFormatStyle {
//        return PhoneNumberFormatStyle()
//    }
//}












//extension PhoneNumber {
//    public func formatted() -> String? {
//        guard let areaCode else { return nil }
//
//        guard areaCode.count == 3 else {
//            return "\(areaCode)"
//        }
//
//        if let exchange, !exchange.isEmpty {
//            if let number, !number.isEmpty {
//                return "(\(areaCode)) \(exchange)-\(number)"
//            } else {
//                return "(\(areaCode)) \(exchange)"
//            }
//        } else {
//            return "(\(areaCode))"
//        }
//    }
//}
