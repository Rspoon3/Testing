//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

@main
struct TestDriveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            Group {
                if coordinator.hasCompletedOnboarding {
                    WorkoutListView(coordinator: coordinator)
                } else {
                    OnboardingView {
                        coordinator.completeOnboarding()
                    }
                }
            }
            .animation(.easeInOut, value: coordinator.hasCompletedOnboarding)
            .onAppear {
                NotificationService.shared.onWorkoutNotificationTapped = { workoutID in
                    coordinator.navigateToWorkout(workoutID: workoutID)
                }
                NotificationService.shared.onWeightNotificationTapped = { weightEntryID in
                    coordinator.navigateToWeightEntry(weightEntryID: weightEntryID)
                }
            }
        }
    }
}
