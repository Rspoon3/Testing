# Features

## PrizeWheel

A vertical slot machine-style prize wheel component built with SwiftUI's `TimelineView` for smooth, continuous animations.

### Key Features

- **Vertical Spinning Wheel**: Displays 7 prize tiles visible at once, spinning from bottom to top in a looping motion
- **Configurable Spin Animation**: Accepts target prize index, number of rotations, duration, and completion handler
- **Ease-Out Curve**: Uses cubic ease-out animation (fast start, gradual slowdown) for realistic slot machine feel
- **Selection Threshold Callbacks**: Notifies when each prize crosses the center selection point during spin, enabling tick sounds and haptic feedback
- **Precise Landing**: Calculates exact distance needed to land precisely on the target prize

### Components

- `Prize` - Model representing a single prize with title, color, and index
- `PrizeTileView` - Individual prize tile display
- `PrizeWheelViewModel` - Manages spin state, animation timing, and threshold detection
- `PrizeWheelView` - Main wheel view using `TimelineView` for animation
- `PrizeWheelContainer` - Wrapper view with environment-based spin controls
- `SpinButton` - Button that triggers the spin via environment
