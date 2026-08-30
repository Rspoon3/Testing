//
//  LiXuanStairClimberSample.swift
//  TestDrive
//

import Foundation

/// The typed contents of one LiXuan `WLT5283M` Stair Climber Data packet.
///
/// Parsing into a struct first, then formatting, keeps the numeric values available
/// to anything that needs to do arithmetic across readings — deriving a step rate,
/// for instance — rather than locking them inside display strings.
struct LiXuanStairClimberSample {

    /// The base value byte 2 counts down from. Observed identical at the start of
    /// every session.
    static let floorCounterBase = 253

    /// The raw 16-bit value occupying the specification's Floors slot.
    let floorsSlotRaw: UInt16

    /// The machine's SPEED level, 0–25. Carried in the Step Per Minute slot.
    let speedLevel: UInt16

    /// The Average Step Rate field, which this firmware never populates.
    let averageStepRate: UInt16

    /// Positive elevation gain, truncated by the firmware to whole metres.
    let elevationGainMetres: UInt16

    /// Cumulative step count.
    let stepCount: UInt16

    /// Cumulative energy in kilocalories, or `nil` when reported unavailable.
    let totalEnergyKilocalories: UInt16?

    /// Heart rate in beats per minute.
    let heartRate: UInt8

    /// Metabolic equivalent, at the specification's 0.1 resolution.
    let metabolicEquivalentRaw: UInt8

    /// Elapsed session time in seconds.
    let elapsedSeconds: UInt16

    /// Remaining session time in seconds.
    let remainingSeconds: UInt16

    /// The floor count, derived from the countdown in byte 2.
    ///
    /// The firmware does not report floors as a number. Byte 2 starts at
    /// ``floorCounterBase`` and decrements once per floor climbed, which was
    /// confirmed against the machine's console across two sessions — at every
    /// transition, not only at the endpoints. Returns `nil` if the byte is outside
    /// the range that relationship holds for, rather than reporting a wrong count.
    var floors: Int? {
        let lowByte = Int(floorsSlotRaw & 0x00FF)
        let highByte = Int(floorsSlotRaw >> 8)

        // Before the first step of a session the machine sends an all-zero packet,
        // which means no floors climbed rather than an unrecognised encoding.
        if floorsSlotRaw == 0 { return 0 }

        guard highByte == 0x10, lowByte <= Self.floorCounterBase else { return nil }
        return Self.floorCounterBase - lowByte
    }
}
