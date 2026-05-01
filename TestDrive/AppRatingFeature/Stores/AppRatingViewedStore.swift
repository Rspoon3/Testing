//
//  AppRatingViewedStore.swift
//  AppRatingFeature
//
//  Created on 9/25/25.
//

import Foundation

/// Protocol for storing app rating view history
public protocol AppRatingViewedStore {
    /// Array of dates when rating was viewed
    var viewedHistory: [Date] { get }

    /// The app version when user last rated
    var lastRatedVersion: String? { get }

    /// Updates the viewed history with a new date
    func updateViewedHistory(adding date: Date)

    /// Sets the last rated version
    func setLastRatedVersion(_ version: String)

    /// Clears all stored data (for testing/debug)
    func clearAll()
}
