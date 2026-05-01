//
//  HealthKitMetrics.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/15/25.
//

import Foundation
import HealthKit

struct HealthKitMetrics: Equatable {
    var stepCount: Int?
    var mindfulnessMinutes: Int?
    var ringValues: ActivityRingValues?
}
