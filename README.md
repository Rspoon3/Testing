# Workout Buddy

An iOS app that delivers AI-powered motivational messages when you complete workouts or log weight entries. The app uses HealthKit background delivery to detect health events and generates personalized messages using ChatGPT.

## Features

- **Workout Detection** - Automatically detects when workouts are completed via HealthKit
- **Weight Tracking** - Monitors weight entries and provides encouragement
- **AI-Powered Messages** - Generates personalized motivational messages using ChatGPT
- **Daily Summaries** - Morning and evening summaries with health insights
- **Background Notifications** - Delivers messages even when the app isn't running

## Architecture

The app uses a layered architecture with clear separation of concerns:

```
HealthKit → HKObserverQuery.stream() → HealthObserver → Callbacks → AppDelegate → BackgroundTaskService
```

### Layer Breakdown

1. **`HKObserverQuery.stream()`** - Low-level AsyncStream wrapper around HealthKit's observer query. Yields a completion handler that must be called after processing to support iOS 26+ background delivery.

2. **`HealthObserver`** - Consumes the stream, fetches the actual workout/weight data, and notifies listeners via `onWorkoutDetected` and `onWeightDetected` callbacks.

3. **`AppDelegate`** - Sets up the observer callbacks and routes detected events to the appropriate service for processing.

4. **`BackgroundTaskService`** - Processes health events by gathering context, generating AI messages, persisting to storage, and scheduling notifications.

### Background Delivery (iOS 26+)

HealthKit background delivery requires the completion handler to be called **after** all processing is complete. The `HKObserverQuery.stream()` extension yields an `HKObserverQueryCompletion` that wraps the completion handler:

```swift
let stream = HKObserverQuery.stream(
    sampleType: workoutType,
    predicate: nil,
    healthStore: healthStore
)

for await completion in stream {
    await handleWorkoutUpdate()
    completion()  // Called AFTER work completes
}
```

This ensures iOS doesn't suspend the app before background work finishes.

## Project Structure

```
TestDrive/
├── App/
│   └── AppDelegate.swift           # Observer setup and lifecycle
├── Models/
│   ├── HealthEvent.swift           # Unified activity type (workout/weight/summary)
│   ├── WorkoutMessage.swift        # Persisted workout messages
│   ├── WeightMessage.swift         # Persisted weight messages
│   └── DailySummaryMessage.swift   # Persisted daily summaries
├── Services/
│   ├── HealthObserver.swift        # HealthKit observer with callbacks
│   ├── BackgroundTaskService.swift # Processes health events
│   ├── DailySummaryService.swift   # Morning/evening summaries
│   ├── HealthKitService.swift      # HealthKit data access
│   └── ChatGPTService.swift        # AI message generation
├── Persistence/
│   ├── WorkoutMessageStore.swift   # JSON persistence for workouts
│   ├── WeightMessageStore.swift    # JSON persistence for weight
│   └── DailySummaryMessageStore.swift # JSON persistence for summaries
├── Features/
│   └── WorkoutList/                # Main activity list UI
└── Extensions/
    └── HKObserverQuery+AsyncStream.swift  # Background-safe observer stream
```

## Requirements

- iOS 17.0+
- Xcode 15+
- HealthKit entitlement
- OpenAI API key (for ChatGPT integration)
