//
//  PointsEarnedViewModel.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 8/27/26.
//

import Observation

/// Drives the state and dummy data for `PointsEarnedView`.
@Observable
final class PointsEarnedViewModel {
    // MARK: - Variables

    var selectedRange: PointsEarnedRange = .month

    // MARK: - Public Helpers

    /// The period of dummy data matching the currently selected range.
    var currentPeriod: PointsEarnedPeriod {
        switch selectedRange {
        case .week: Self.weekPeriod
        case .month: Self.monthPeriod
        case .year: Self.yearPeriod
        }
    }

    // MARK: - Private Helpers

    private static let weekPeriod = PointsEarnedPeriod(
        title: "June 14 – 20, 2026",
        receiptCount: 9,
        totalPoints: 3_383,
        dataPoints: [
            PointsEarnedDataPoint(x: 0, points: 0),
            PointsEarnedDataPoint(x: 1, points: 150),
            PointsEarnedDataPoint(x: 2, points: 1_400),
            PointsEarnedDataPoint(x: 3, points: 1_575),
            PointsEarnedDataPoint(x: 4, points: 0),
            PointsEarnedDataPoint(x: 5, points: 225),
            PointsEarnedDataPoint(x: 6, points: 15),
        ],
        axisTickPositions: [0, 1, 2, 3, 4, 5, 6],
        axisLabels: [
            0: "Sun",
            1: "Mon",
            2: "Tue",
            3: "Wed",
            4: "Thu",
            5: "Fri",
            6: "Sat",
        ]
    )

    private static let monthPeriod = PointsEarnedPeriod(
        title: "Apr 2026",
        receiptCount: 94,
        totalPoints: 2_290,
        dataPoints: {
            let pointsByDay: [Int: Double] = [
                3: 50, 8: 220, 9: 20, 11: 150, 13: 50, 16: 45, 18: 25, 19: 25,
                21: 225, 22: 375, 23: 440, 25: 45, 26: 125, 27: 150, 28: 180, 29: 75, 30: 50,
            ]
            return (1...30).map { day in
                PointsEarnedDataPoint(x: day, points: pointsByDay[day] ?? 0)
            }
        }(),
        axisTickPositions: [1, 15, 30],
        axisLabels: [
            1: "Apr 1",
            15: "Apr 15",
            30: "Apr 30",
        ]
    )

    private static let yearPeriod = PointsEarnedPeriod(
        title: "2026",
        receiptCount: 53,
        totalPoints: 5_747,
        dataPoints: [
            PointsEarnedDataPoint(x: 1, points: 0),
            PointsEarnedDataPoint(x: 2, points: 0),
            PointsEarnedDataPoint(x: 3, points: 875),
            PointsEarnedDataPoint(x: 4, points: 150),
            PointsEarnedDataPoint(x: 5, points: 225),
            PointsEarnedDataPoint(x: 6, points: 4_150),
            PointsEarnedDataPoint(x: 7, points: 225),
            PointsEarnedDataPoint(x: 8, points: 0),
            PointsEarnedDataPoint(x: 9, points: 0),
            PointsEarnedDataPoint(x: 10, points: 0),
            PointsEarnedDataPoint(x: 11, points: 0),
            PointsEarnedDataPoint(x: 12, points: 0),
        ],
        axisTickPositions: Array(1...12),
        axisLabels: [
            1: "Jan", 2: "Feb", 3: "Mar", 4: "Apr",
            5: "May", 6: "Jun", 7: "Jul", 8: "Aug",
            9: "Sep", 10: "Oct", 11: "Nov", 12: "Dec",
        ]
    )
}
