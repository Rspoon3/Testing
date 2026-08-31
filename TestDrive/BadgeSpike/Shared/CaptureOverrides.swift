//
//  CaptureOverrides.swift
//  TestDrive
//

import Foundation

/// Launch-argument overrides for capturing the tabs side by side.
///
/// Comparing five rendering techniques only means something if they are all frozen
/// at the same angle. Left to the idle drift, every screenshot catches the badge
/// somewhere different and the differences on screen are dominated by pose rather
/// than by technique.
///
/// Debug-only. Usage:
/// ```
/// xcrun simctl launch <device> com.rspoon3.TestDrive -badgeTab shader -badgeAngle 55
/// ```
enum CaptureOverrides {

    // MARK: - Public Helpers

    /// A fixed spin angle in degrees, if one was requested.
    ///
    /// When set, the idle drift is suppressed so the pose holds still.
    static var angle: Double? {
        #if DEBUG
        guard UserDefaults.standard.object(forKey: "badgeAngle") != nil else { return nil }
        return UserDefaults.standard.double(forKey: "badgeAngle")
        #else
        return nil
        #endif
    }

    /// Whether the badge should hold a fixed pose rather than drifting.
    static var isFrozen: Bool {
        angle != nil
    }
}
