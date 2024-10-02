//
//  prefix.swift
//  Testing
//
//  Created by Ricky on 10/1/24.
//
import Foundation

func applyUSAFormat(to input: String) -> String {
    let cleanedInput = input.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)

    let areaCode = cleanedInput.prefix(3)
    let exchange = cleanedInput.dropFirst(3).prefix(3)
    let lineNumber = cleanedInput.dropFirst(6).prefix(4)
    
    guard areaCode.count == 3 else {
        return "\(areaCode)"
    }
    
    if !exchange.isEmpty {
        if !lineNumber.isEmpty {
            return "(\(areaCode)) \(exchange)-\(lineNumber)"
        } else {
            return "(\(areaCode)) \(exchange)"
        }
    } else {
        return "(\(areaCode))"
    }
}
