//
//  PhoneNumberError.swift
//  Testing
//
//  Created by Ricky on 10/28/24.
//

import Foundation

public enum PhoneNumberError: Error {
    case invalidAreaCode
    case invalidExchange
    case invalidNumber
}
