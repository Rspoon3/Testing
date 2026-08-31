//
//  Badge.swift
//  TestDrive
//

import SwiftUI

/// A sample landmark badge, standing in for what SyncStairs would derive from
/// lifetime floor totals.
struct Badge: Identifiable, Hashable {
    let id = UUID()

    /// The landmark's name, e.g. "Empire State Building".
    let title: String

    /// How many times the landmark has been climbed.
    let count: Int

    /// The SF Symbol engraved on the face.
    let symbolName: String

    /// The metal the medallion is struck from — drives every tab's palette.
    let finish: BadgeFinish

    /// When the badge was first earned, engraved on the reverse.
    let earnedDate: Date

    // MARK: - Public Helpers

    /// The multiplier shown under the badge, e.g. "×8".
    var formattedCount: String {
        "×\(count)"
    }

    /// The earned date as engraved on the reverse, e.g. "MAR 3, 2026".
    ///
    /// Uppercased because it is struck into metal, where mixed case reads as a label
    /// rather than as an engraving.
    var formattedEarnedDate: String {
        earnedDate
            .formatted(.dateTime.month(.abbreviated).day().year())
            .uppercased()
    }
}

extension Badge {
    /// The sample set used by every tab, so the approaches are compared on
    /// identical artwork.
    static let samples: [Badge] = [
        Badge(
            title: "Empire State Building",
            count: 8,
            symbolName: "building.2.fill",
            finish: .gold,
            earnedDate: .daysAgo(214)
        ),
        Badge(
            title: "Eiffel Tower",
            count: 3,
            symbolName: "sparkles",
            finish: .silver,
            earnedDate: .daysAgo(96)
        ),
        Badge(
            title: "Burj Khalifa",
            count: 1,
            symbolName: "building.columns.fill",
            finish: .bronze,
            earnedDate: .daysAgo(11)
        ),
        Badge(
            title: "Mount Everest",
            count: 12,
            symbolName: "mountain.2.fill",
            finish: .cosmic,
            earnedDate: .daysAgo(430)
        )
    ]
}

private extension Date {
    /// A date the given number of days before now, for sample data.
    /// - Parameter days: How far back to go.
    /// - Returns: The offset date.
    static func daysAgo(_ days: Int) -> Date {
        .now.addingTimeInterval(-Double(days) * 86_400)
    }
}
