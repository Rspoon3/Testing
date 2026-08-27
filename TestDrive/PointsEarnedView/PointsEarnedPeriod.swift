//
//  PointsEarnedPeriod.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 8/27/26.
//

import Foundation

/// A single period of points-earned data, such as one week, one month, or one year.
struct PointsEarnedPeriod {
    let title: String
    let receiptCount: Int
    let totalPoints: Int
    let dataPoints: [PointsEarnedDataPoint]
    let axisTickPositions: [Int]
    let axisLabels: [Int: String]
}
