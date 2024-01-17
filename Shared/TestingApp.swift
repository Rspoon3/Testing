//
//  TestingApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import SwiftData

@main
struct TestingApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print(URL.applicationSupportDirectory.path(percentEncoded: false))
                }
        }
        .modelContainer(
            for: [
                Workout.self,
                WorkoutEntry.self,
                ExerciseSet.self,
                Exercise.self,
                MuscleGroup.self,
                MassUnit.self
            ]
        )
    }
}
