//
//  Extension+HKQuantity.swift
//  Extension+HKQuantity
//
//  Created by Richard Witherspoon on 8/1/21.
//

import Foundation
import HealthKit

extension HKQuantity{
    func integerValue(for unit: HKUnit)->Int{
        Int(doubleValue(for: unit))
    }
}
