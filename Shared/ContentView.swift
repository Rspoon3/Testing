//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import SwiftData
import LoremSwiftum

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MuscleGroup.title, order: .forward)
    var muscleGroups: [MuscleGroup]
    
    @Query(sort: \Exercise.title, order: .forward)
    var exercises: [Exercise]
    
    @Query(sort: \Workout.startDate, order: .forward)
    var workouts: [Workout]
    
    @Query var massUnits: [MassUnit]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(muscleGroups) { item in
                        HStack {
                            Text(item.title)
//                            Circle()
//                                .foregroundStyle(Color(item.uiColor))
//                                .frame(width: 20, height: 20)
                        }
                    }
                }
                
                Section {
                    ForEach(exercises) { exercise in
                        LabeledContent {
                            Text(exercise.muscleGroups.map(\.title).formatted())
                        } label: {
                            Text(exercise.title)
                        }
                    }
                }
                
                Section {
                    ForEach(workouts) { workout in
                        VStack(alignment: .leading) {
                            Text(workout.title)
                            Text(workout.entires.count.formatted())
                            Text(workout.entires.first!.creationDate.formatted())
                            Text(workout.entires.first!.note ?? "")
                            Text(workout.entires.first!.sets.count.description)
                            Text(workout.entires.first!.sets.first?.totalWeight.value.formatted() ?? "")
                        }
                    }
                    .onDelete { set in
                        for index in set {
                            if let set = workouts[index].entires.first!.sets.first {
                                modelContext.delete(set)
                            } else {
                                modelContext.delete(workouts[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle(massUnits.count.description)
            .toolbar {
                ToolbarItem {
                    Button("Add Item") {
                        addExcersises()
                        //
                        let workout = Workout(title: Lorem.title, startDate: .now)
                        let unit = MassUnit(weight: 11, unit: .pounds)
                        let set = ExerciseSet(creationDate: .now, reps: 10, repGoal: 10, massUnit: unit)
                        let set2 = ExerciseSet(creationDate: .now, reps: 4, repGoal: 3, massUnit: unit)
                        let set3 = ExerciseSet(creationDate: .now, reps: 4, repGoal: 3, massUnit: unit)
                        let set4 = ExerciseSet(creationDate: .now, reps: 4, repGoal: 3, massUnit: unit)
                        let entry = WorkoutEntry(
                            exercise: exercises.randomElement()!,
                            note: "test note",
                            sets: [set,set2,set3,set4],
                            creationDate: .now
                        )
                        workout.entires.append(entry)
                        
                        modelContext.insert(workout)
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete") {
                        for muscleGroup in muscleGroups {
                            modelContext.delete(muscleGroup)
                        }
                    }
                }
            }
            .onAppear {
                let descriptor = FetchDescriptor<MuscleGroup>()
                let count = (try? modelContext.fetchCount(descriptor)) ?? 0
                guard count == 0 else { return }
                
                let groups = ["Arms", "Back", "Chest", "Core", "Legs", "Shoulders", "Full Body", "Glutes", "Other"]
                
                for group in groups {
                    let muscleGroup = MuscleGroup(title: group, uiColor: .random())
                    modelContext.insert(muscleGroup)
                }
            }
        }
    }
    
    func addExcersises() {
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        
        let bench = Exercise(
            title: "Bench Press",
            isUserCreated: false
        )
        bench.muscleGroups.append(muscleGroups.randomElement()!)
        
        let arms = Exercise(
            title: "Single Arm Rows",
            isUserCreated: false
        )
        arms.muscleGroups.append(muscleGroups.randomElement()!)

        let squats = Exercise(
            title: "Squats",
            isUserCreated: true
        )
        squats.muscleGroups.append(muscleGroups.randomElement()!)
        squats.muscleGroups.append(muscleGroups.randomElement()!)

        modelContext.insert(bench)
        modelContext.insert(arms)
        modelContext.insert(squats)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
