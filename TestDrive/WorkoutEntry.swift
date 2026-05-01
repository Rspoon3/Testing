//
//  WorkoutEntry.swift
//  Workouts
//
//  Created by Richard Witherspoon on 1/7/24.
//

import Foundation
import SwiftData

@Model
public class WorkoutEntry {
    public var exercise: Exercise
    public var note: String? = nil
    private(set) var creationDate: Date
    
    @Relationship(deleteRule: .cascade)
    public var sets: [ExerciseSet] = []
    
    public init(
        exercise: Exercise,
        note: String? = nil,
        sets: [ExerciseSet],
        creationDate: Date
    ) {
        self.exercise = exercise
        self.note = note
        self.sets = sets
        self.creationDate = creationDate
    }
}
