# Features

## Meeting Border (macOS)

A pulsing glow appears around every connected display shortly before any
meeting on the user's calendar, accompanied by a drop-down toast banner with
a Join button when the event includes a Zoom/Meet/Teams link.

- `MeetingMonitor` — `@Observable` model. Reads EventKit, ticks once per second,
  fires the overlay + toast at the right moment, and persists timing/color via
  `PersistedSettings` (UserDefaults).
- `GlowingBorderView` — SwiftUI border using `TimelineView(.animation)` for a
  smooth color-configurable pulse.
- `GlowingBorderController` — One borderless click-through `NSPanel` per screen.
- `MeetingToastView` / `MeetingToastController` — Top-of-screen banner with
  countdown (`TimelineView(.periodic)`) and optional Join button.
- `DebugSettingsView` (Settings scene, ⌘,) — Sliders for lead/duration, color
  picker, and Trigger/Hide buttons for both glow and toast.
- Tests cover URL extraction from event notes/location, fallback titles, and
  UserDefaults round-tripping of settings.
