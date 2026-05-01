//
//  ConsoleAppRatingAnalyticsRecorder.swift
//  HotTakesCore
//
//  Created by Ricky Witherspoon on 9/25/25.
//

import Foundation

/// Default implementation that prints to console (replace with your analytics service)
public struct ConsoleAppRatingAnalyticsRecorder: AppRatingAnalyticsRecording {
    public init() {}

    public func recordEvent(_ event: AppRatingAnalyticsEvent) {
        switch event {
        case .askToAskViewed:
            print("📊 Analytics: App rating ask-to-ask viewed")
        case .starsSelected(let count):
            print("📊 Analytics: User selected \(count) stars")
        case .dismissed:
            print("📊 Analytics: App rating dismissed")
        case .nativePromptShown:
            print("📊 Analytics: Native app store prompt shown")
        case .notEligible(let reason):
            print("📊 Analytics: User not eligible - \(reason.rawValue)")
        }
    }
}
