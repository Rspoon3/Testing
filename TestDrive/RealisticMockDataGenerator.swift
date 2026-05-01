//
//  RealisticMockDataGenerator.swift
//  Testing
//
//  Created by Ricky on 12/20/24.
//

import Foundation

final class RealisticMockDataGenerator {
    private var lastCadence: Int
    private var lastResistance: Int
    private var lastSpeed: Int
    
    init(initialCadence: Int = 80, initialResistance: Int = 10, initialSpeed: Int = 20) {
        self.lastCadence = initialCadence
        self.lastResistance = initialResistance
        self.lastSpeed = initialSpeed
    }
    
    /// Generate the next realistic cadence value
    func nextCadence() -> Int {
        lastCadence = generateNextValue(currentValue: lastCadence, range: 50...120, maxChange: 3)
        return lastCadence
    }
    
    /// Generate the next realistic resistance value
    func nextResistance() -> Int {
        lastResistance = generateNextValue(currentValue: lastResistance, range: 1...31, maxChange: 1)
        return lastResistance
    }
    
    /// Generate the next realistic speed value
    func nextSpeed() -> Int {
        lastSpeed = generateNextValue(currentValue: lastSpeed, range: 5...30, maxChange: 3)
        return lastSpeed
    }
    
    /// Generate the next value with gradual changes
    private func generateNextValue(currentValue: Int, range: ClosedRange<Int>, maxChange: Int) -> Int {
        // Add a small random change, either positive or negative
        let change = Int.random(in: -maxChange...maxChange)
        let newValue = currentValue + change
        
        // Ensure the new value is within the specified range
        return max(range.lowerBound, min(range.upperBound, newValue))
    }
}
