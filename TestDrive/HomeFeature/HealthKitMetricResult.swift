//
//  HealthKitMetricResult.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/15/25.
//

import Foundation

enum HealthKitMetricResult {
    case stepCount(Int)
    case mindfulnessMinutes(Int)
    case ringValues(ActivityRingValues)
}
