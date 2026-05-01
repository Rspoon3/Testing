//
//  AppRatingAnalyticsRecording.swift
//  HotTakesCore
//
//  Created by Ricky Witherspoon on 9/25/25.
//

import Foundation

/// Protocol for recording app rating analytics
public protocol AppRatingAnalyticsRecording {
    func recordEvent(_ event: AppRatingAnalyticsEvent)
}
