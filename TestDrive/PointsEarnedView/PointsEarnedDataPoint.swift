//
//  PointsEarnedDataPoint.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 8/27/26.
//

import Foundation

/// A single bar in the points-earned chart.
struct PointsEarnedDataPoint: Identifiable {
    let id = UUID()
    let x: Int
    let points: Double
}
