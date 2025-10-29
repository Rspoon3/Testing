# Features

This document tracks major features in the TestDrive project.

## Button Haptic Feedback

Provides sensory (haptic) feedback for buttons using a custom `ButtonStyle` that leverages SwiftUI's `.sensoryFeedback` modifier.

**Implementation:**
- `HapticButtonStyle`: A custom `ButtonStyle` that applies `.sensoryFeedback(feedback, trigger: configuration.isPressed)`
- Uses only SwiftUI's native `.sensoryFeedback` modifier (no UIKit haptic generators)
- Supports all `SensoryFeedback` types: `.impact`, `.selection`, `.success`, `.warning`, `.error`, etc.

### Usage

Apply `.hapticButtonStyle()` to any button to add haptic feedback:

```swift
// Default haptic (impact)
Button("Tap Me") {
    print("Button tapped")
}
.hapticButtonStyle()

// Custom haptic type
Button("Success") {
    print("Success")
}
.hapticButtonStyle(.success)

// Works with roles
Button("Delete", role: .destructive) {
    print("Delete tapped")
}
.hapticButtonStyle(.error)

// Works with custom labels
Button {
    print("Custom label")
} label: {
    HStack {
        Image(systemName: "star")
        Text("Favorite")
    }
}
.hapticButtonStyle(.selection)

// Regular button without haptic
Button("No Haptic") {
    print("No feedback")
}
```

You can also use the standard `.buttonStyle(.haptic())` syntax:

```swift
Button("Tap Me") {
    print("Tapped")
}
.buttonStyle(.haptic)

Button("Success") {
    print("Success")
}
.buttonStyle(.haptic(.success))
```

### Apply Globally

You can apply haptic feedback to all buttons in a view hierarchy:

```swift
VStack {
    Button("Button 1") { }
    Button("Button 2") { }
    Button("Button 3") { }
}
.hapticButtonStyle()
```

Or at the app level:

```swift
WindowGroup {
    ContentView()
        .hapticButtonStyle()
}
```

Both `.hapticButtonStyle()` and `.buttonStyle(.haptic)` work the same way when applied globally.

### Technical Details

The `HapticButtonStyle` uses SwiftUI's `.sensoryFeedback` modifier with `configuration.isPressed` as the trigger:

```swift
func makeBody(configuration: Configuration) -> some View {
    configuration.label
        .sensoryFeedback(feedback, trigger: configuration.isPressed)
}
```

This ensures haptics fire whenever the button is pressed, using only SwiftUI's native APIs.

### Benefits
- Clean, declarative SwiftUI approach
- Convenient `.hapticButtonStyle()` syntactic sugar
- Uses only SwiftUI's `.sensoryFeedback` (no UIKit dependencies)
- Works with all Button features (roles, custom labels, string protocols)
- Can be applied globally or per-button
- Default value of `.impact` makes it easy to add basic haptics
- Doesn't interfere with standard SwiftUI Button usage
