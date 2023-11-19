//
//  HKQuantityTypeIdentifier+Title.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/18/23.
//

import Foundation
import HealthKit


extension HKQuantityTypeIdentifier {
    var title: String {
        rawValue.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "")
    }
}
