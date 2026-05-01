//
//  ActivityRingValues.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/15/25.
//

import Foundation
import HealthKit

struct ActivityRingValues: Equatable {
    let summary: HKActivitySummary
    let move: Double
    let moveGoal: Double
    let exercise: Double
    let exerciseGoal: Double
    let stand: Double
    let standGoal: Double
    
    var allClosed: Bool {
        move >= moveGoal && exercise >= exerciseGoal && stand >= standGoal
    }
    
    init(summary: HKActivitySummary) {
        self.summary = summary
        self.move = summary.activeEnergyBurned.doubleValue(for: .kilocalorie())
        self.moveGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())

        self.exercise = summary.appleExerciseTime.doubleValue(for: .minute())
        self.exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: .minute())

        self.stand = summary.appleStandHours.doubleValue(for: .count())
        self.standGoal = summary.appleStandHoursGoal.doubleValue(for: .count())
    }
}
