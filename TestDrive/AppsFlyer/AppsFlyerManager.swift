//
//  AppsFlyerManager.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 6/5/26.
//

import Foundation

/// Mimics the AppsFlyer SDK listeners used in the production app so their
/// behavior can be reproduced without the real SDK.
///
/// AppsFlyer surfaces attribution data through three listeners:
/// - `onConversionDataSuccess` fires on every app load.
/// - `onAppOpenAttribution` and `onDeeplink` fire only when the app is opened
///   through a deep link.
@Observable
final class AppsFlyerManager {

    // MARK: - Listeners

    /// AppsFlyer's conversion-data listener. Fires on every app load.
    /// - Returns: The referral code provided by AppsFlyer.
    func onConversionDataSuccess() -> String {
        send("RICKY1", source: .conversion)
    }

    /// AppsFlyer's legacy attribution listener. Fires on deep link only.
    /// - Returns: The referral code provided by AppsFlyer.
    func onAppOpenAttribution() -> String {
        send("RICKY1", source: .deeplink)
    }

    /// AppsFlyer's unified deep link listener. Fires on deep link only.
    /// - Returns: The referral code provided by AppsFlyer.
    func onDeeplink() -> String {
        send("RICKY1", source: .deeplink)
    }

    // MARK: - Private Helpers

    /// Sends a value tagged with the source that produced it.
    /// - Parameters:
    ///   - value: The payload to send.
    ///   - source: The AppsFlyer listener that produced the value.
    /// - Returns: The sent value.
    private func send(_ value: String, source: AnalyticsSource) -> String {
        print("Sending \"\(value)\" from \(source)")
        return value
    }
}
