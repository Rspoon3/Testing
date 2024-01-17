//
//  Workout.swift
//  Workouts
//
//  Created by Richard Witherspoon on 1/7/24.
//

import Foundation
import SwiftData

@Model
public class Workout {
    public var title: String
    public var startDate: Date
    public var endDate: Date?
    
    @Relationship(deleteRule: .cascade)
    public var entires: [WorkoutEntry] = []
    
    init(
        title: String,
        startDate: Date,
        endDate: Date? = nil
    ) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
    }
}

