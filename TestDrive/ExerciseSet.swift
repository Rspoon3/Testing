//
//  ExerciseSet.swift
//  Workouts
//
//  Created by Richard Witherspoon on 1/7/24.
//

import Foundation
import SwiftData

@Model
public class ExerciseSet {
    public var creationDate: Date
    public var reps: Int
    public var repGoal: Int
    
    @Relationship(deleteRule: .cascade)
    private let massUnit: MassUnit
    
    var totalWeight: Measurement<UnitMass> {
        massUnit.measurement * Double(reps)
    }
    
    var hitGoal: Bool {
        return reps >= repGoal
    }
    
    init(
        creationDate: Date,
        reps: Int,
        repGoal: Int,
        massUnit: MassUnit
    ) {
        self.creationDate = creationDate
        self.reps = reps
        self.repGoal = repGoal
        self.massUnit = massUnit
    }
}
