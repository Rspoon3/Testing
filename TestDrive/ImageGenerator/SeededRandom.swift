import Foundation

/// A seeded random number generator for reproducible pattern layouts.
final class SeededRandom {
    private var state: UInt64

    /// Creates a seeded random generator.
    /// - Parameter seed: The seed value for reproducible randomness.
    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed &* 6364136223846793005 &+ 1442695040888963407))
        if state == 0 { state = 1 }
    }

    /// Returns a random Double between 0 and 1.
    func nextDouble() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 33) / Double(UInt64(1) << 31)
    }

    /// Returns a random Double in the given range.
    func nextDouble(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextDouble() * (range.upperBound - range.lowerBound)
    }
}
