# Features

## Workout Buddy MVP

### Onboarding Word Cloud
Animated floating word cloud displayed on first launch. Users tap to select their preferred AI coach "attitude" (tone). The selected attitude persists and influences how ChatGPT responds to workout completions.

### Workout List
Main screen showing the user's workouts from the last 30 days via HealthKit. Displays workout type, duration, calories burned, and date.

### Settings
Allows users to change their selected attitude after onboarding. Accessible from the main workout list screen.

### Background Workout Detection
Monitors HealthKit for completed workouts using HKObserverQuery with background delivery. Supports popular workout types: running, walking, cycling, strength training, HIIT, and yoga.

### ChatGPT Integration
Sends completed workout details to OpenAI's ChatGPT API along with the user's selected attitude. Receives a personalized message to deliver to the user.

### Push Notifications
Delivers AI-generated personalized messages as local notifications when a workout is detected in the background.

### AI Provider Abstraction
Supports multiple AI providers for message generation. Users on iOS 26+ can choose between ChatGPT (cloud-based) and Apple's Foundation Model (on-device). The abstraction uses a protocol-based design with factory pattern for extensibility.

### Regenerate Message
Debug feature on activity detail pages (workout, weight, daily summary) allowing users to regenerate AI messages using the currently selected provider. Useful for A/B testing between ChatGPT and Foundation Model outputs.
