# Menu Bar

A `MenuBarExtra` status item showing a calendar icon and an optional countdown
to the next meeting. Clicking it reveals the next meeting summary with a Join
button (when the event has a Zoom/Meet/Teams link), a Settings link, and Quit.

The item is toggled on/off from Debug Settings (`Show menu bar item`) and the
preference is persisted via `PersistedSettings`.

## Components

- `MenuBarLabel` — The compact label shown in the menu bar: calendar icon plus
  an optional pre-formatted countdown string.
- `MenuBarContent` — The popup content rendered when the item is clicked. Reads
  `nextEvent` from `MeetingMonitor` and exposes Join / Settings / Quit actions.
- Wiring lives in `TestDriveApp.swift` (`MenuBarExtra` scene).

The countdown string is produced by `MeetingMonitor.updateMenuBarCountdown()`,
called from the monitor's existing 1Hz tick (and on event refresh / when the
menu bar toggle flips). The countdown is only populated when the next event is
within the next hour, otherwise the label shows just the icon.

## Why the countdown is updated manually (and not via `Text(_, style: .timer)`)

The first implementation used `Text(nextEvent, style: .timer)` inside the
`MenuBarExtra` label, on the theory that a self-updating timer text would be
cheaper than driving the label from an external timer. In practice it pinned
CPU at 100% and grew memory until the app beachballed.

The cause is how `MenuBarExtra` with `.menuBarExtraStyle(.menu)` renders its
label: SwiftUI extracts the label's text/image content and assigns it directly
to `NSStatusItem.button.title` / `.image`. The SwiftUI view tree is **not**
hosted live in the status item. So `.timer` style — which constantly publishes
new text — forces SwiftUI to re-extract and re-assign the title at the timer's
internal rate, every frame. That re-extraction churns memory and saturates the
main thread.

The fix is to render plain static `Text` and let `MeetingMonitor` push a fresh
countdown string into the view once per second from its existing tick. One
re-assignment per second instead of every frame.

Side note: the same extraction is also why SwiftUI font modifiers like
`.monospacedDigit()` are dropped in the menu bar label — the status item uses
the system menu bar font regardless. If you need stable-width digits, pad the
string manually (e.g. `String(format: "%2d:%02d", m, s)`) rather than relying
on the modifier.

## Related files

- `TestDrive/MeetingMonitor/MeetingMonitor.swift` — owns `menuBarCountdown` and
  `showMenuBarItem`, drives the 1Hz update.
- `TestDrive/MeetingMonitor/PersistedSettings.swift` — UserDefaults backing for
  `showMenuBarItem`.
- `TestDrive/DebugSettings/DebugSettingsView.swift` — the toggle UI.
- `TestDrive/TestDriveApp.swift` — `MenuBarExtra` scene wiring.
