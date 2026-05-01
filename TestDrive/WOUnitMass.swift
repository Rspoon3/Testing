//
//  WOUnitMass.swift
//  Workouts
//
//  Created by Richard Witherspoon on 1/7/24.
//

import Foundation

public enum WOUnitMass: Int, Codable {
    case pounds = 0
    case kilograms = 1
     
    public var unitMass: UnitMass {
        switch self {
        case .pounds:
            return .pounds
        case .kilograms:
            return .kilograms
        }
    }
}
