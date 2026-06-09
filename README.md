# TestDrive

A multi-platform Xcode project for experimenting with various iOS, iPadOS, watchOS, and macOS development concepts.

## Overview

This repository serves as a testing ground for different development ideas across Apple's platforms. Each branch contains specific experiments or feature implementations.

## Platforms

- **iOS** - Primary development platform
- **iPadOS** - Tablet-optimized features and layouts
- **watchOS** - Apple Watch companion features (occasional)
- **macOS** - Desktop application experiments (occasional)

## Branch Structure

Different branches are used to isolate and test various concepts. Check the branch list to explore specific features or experiments.

**Important:** Never commit directly to `main`. The main branch serves as a clean starting point for new experiments. Always create a new branch for your work.

## This Branch: AppsFlyer Referral Eligibility (`Fetch/appsflyer-fix`)

A mimic of an AppsFlyer-driven referral flow, used to reproduce and fix how referral codes are sent to the backend for eligibility — including across multiple users.

### Flow

1. **AppsFlyer listeners** (`AppsFlyerManager`) mimic the SDK callbacks and each return a referral code (`RICKY1`):
   - `onConversionDataSuccess` → tagged `.conversion`, fires on every app open.
   - `onAppOpenAttribution` / `onDeeplink` → tagged `.deeplink`, fire only on a deep link open.
2. Incoming codes are recorded in a persisted **ledger** (`ReferralCodeStore`). Each `ReferralCode` stores the code, date, `AnalyticsSource`, `userID`, and a `Status` (`.unresolved` / `.resolved(.valid | .invalid)`). The ledger is written to `UserDefaults`, so a code captured at launch survives a quit before it is processed.
3. On the home screen, a 3‑second `TimelineView` countdown runs. When it finishes, every unresolved code is sent to the mocked backend (`ReferralBackend`), which enforces **one referral code per user** and returns eligibility. The result is written back to the ledger.
4. If a code is **ineligible**, a red box is shown for two seconds.

### Behavior

- A user's first code resolves **valid**; re-using a code (e.g. opening via deep link again) resolves **invalid** → red box.
- The conversion is recorded once **per user**; a deep link is always treated as a fresh attempt and restarts the countdown so it is re-checked.
- Switching users (see below) re-sends the referral for the newly logged-in user, so eligibility is tracked independently per user.

### Testing it

- **Deep link** (registered scheme `testdrive://`):
  ```bash
  xcrun simctl openurl booted "testdrive://x"
  ```
- **Switch users**: the gear button (upper-left) opens Settings with a picker for three user IDs (`user-123`, `user-456`, `user-789`). Each user has independent eligibility.

### Tests

A Swift Testing suite (`TestDriveTests`) covers single-user and multi-user scenarios across `ReferralBackend`, `ReferralCodeStore`, `AppsFlyerManager`, `HomeViewModel`, and `SettingsViewModel`.

```bash
xcodebuild test -project TestDrive.xcodeproj -scheme TestDrive \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Getting Started

1. Clone the repository
2. Open the `.xcodeproj` file in Xcode
3. Select your target platform and device
4. Build and run

## Requirements

- Xcode (latest version recommended)
- macOS development environment
- iOS/iPadOS Simulator or physical device for testing