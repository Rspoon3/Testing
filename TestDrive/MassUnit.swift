//
//  MassUnit.swift
//  Testing
//
//  Created by Richard Witherspoon on 1/13/24.
//

import Foundation
import SwiftData

/// Store weight in pounds so we can easily do SwiftData lookups
@Model public final class MassUnit {
    private let pounds: Double
    private let unit: WOUnitMass
    
    public var measurement: Measurement<UnitMass> {
        let pounds = Measurement(value: pounds, unit: UnitMass.pounds)
        
        switch unit {
        case .pounds:
            return pounds
        case .kilograms:
            return pounds.converted(to: .kilograms)
        }
    }

    init(weight: Double, unit: WOUnitMass) {
        self.unit = unit

        switch unit {
        case .pounds:
            self.pounds = weight
        case .kilograms:
            let kilograms = Measurement(value: weight, unit: UnitMass.kilograms)
            self.pounds = kilograms.converted(to: .pounds).value
        }
    }
}
