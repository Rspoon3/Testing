//
//  Weekday.swift
//  TestDrive
//

import Foundation

/// Days of the week. Raw values match Foundation's `Calendar` convention
/// (1 = Sunday, 7 = Saturday) so the value can be compared directly against
/// `dateComponents([.weekday], from: now).weekday`.
enum Weekday: Int, Codable, CaseIterable, Identifiable, Hashable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: Int { rawValue }

    /// Single-character label used in the alarm editor's repeat picker.
    var shortSymbol: String {
        switch self {
        case .sunday: "S"
        case .monday: "M"
        case .tuesday: "T"
        case .wednesday: "W"
        case .thursday: "T"
        case .friday: "F"
        case .saturday: "S"
        }
    }

    /// Three-letter abbreviation used in alarm row subtitles.
    var abbreviation: String {
        switch self {
        case .sunday: "Sun"
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        }
    }
}
