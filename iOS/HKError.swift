//
//  HKError.swift
//  HKError
//
//  Created by Richard Witherspoon on 8/1/21.
//

import Foundation

enum HKError: LocalizedError{
    case notAuthorized(error: Error)
    case noSamples
    case noStatistics
    case noCollections
    case noSumQuantity
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized(let error):
            return "An error occurred while requesting HealthKit Authorization:: \(error.localizedDescription)."
        case .noSamples:
            return "No samples could be found."
        case .noCollections:
            return "No collections could be found."
        case .noSumQuantity:
            return "The sum could not be calculated."
        case .noStatistics:
            return "The statistics could not be calculated."
        }
    }
}
