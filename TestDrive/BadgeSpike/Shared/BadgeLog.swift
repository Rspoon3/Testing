//
//  BadgeLog.swift
//  TestDrive
//

import OSLog

/// Logging for the badge spike.
///
/// The RealityKit tabs do several things that can each stall for their own reasons
/// — rasterizing artwork, convolving an environment map, compiling materials — and
/// a blank view says nothing about which. Filter the simulator log on
/// `subsystem: com.rspoon3.TestDrive`.
let badgeLog = Logger(subsystem: "com.rspoon3.TestDrive", category: "BadgeSpike")

/// Times a step and logs how long it took.
/// - Parameters:
///   - label: What is being measured.
///   - work: The step.
/// - Returns: Whatever `work` returns.
func timed<T>(_ label: String, _ work: () async throws -> T) async rethrows -> T {
    let start = ContinuousClock.now
    badgeLog.info("→ \(label, privacy: .public)")
    let value = try await work()
    let elapsed = ContinuousClock.now - start
    badgeLog.info("✓ \(label, privacy: .public) in \(elapsed.description, privacy: .public)")
    return value
}
