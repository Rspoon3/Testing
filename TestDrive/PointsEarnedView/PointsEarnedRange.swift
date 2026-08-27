//
//  PointsEarnedRange.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 8/27/26.
//

import Foundation

/// The time granularity used to bucket points-earned data.
enum PointsEarnedRange: String, CaseIterable, Identifiable {
    case week
    case month
    case year

    var id: Self { self }

    /// The label displayed in the range picker.
    var title: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }
}
