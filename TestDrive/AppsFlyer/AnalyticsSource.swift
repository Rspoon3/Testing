//
//  AnalyticsSource.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 6/5/26.
//

import Foundation

/// Identifies which AppsFlyer callback triggered a value being sent.
enum AnalyticsSource: String, Codable {
    /// Produced by `onConversionDataSuccess`, which fires on every app load.
    case conversion

    /// Produced by `onAppOpenAttribution` and `onDeeplink`, which fire on deep link only.
    case deeplink
}
