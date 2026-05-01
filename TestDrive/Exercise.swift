//
//  ExerciseType.swift
//  Workouts
//
//  Created by Richard Witherspoon on 1/7/24.
//

import Foundation
import SwiftData


@Model
public class Exercise {
    public var title: String
    public var muscleGroups: [MuscleGroup] = []
    public var isFavorite: Bool
    private(set) var creationDate: Date
    private(set) var isUserCreated: Bool
    
    init(
        title: String,
        isFavorite: Bool = false,
        isUserCreated: Bool
    ) {
        self.title = title
        self.isFavorite = isFavorite
        self.creationDate = .now
        self.isUserCreated = isUserCreated
    }
}
