import Foundation

/// A persisted message generated for a weight entry.
struct WeightMessage: Codable, Identifiable, Hashable {
    let id: String
    let weightEntryID: String
    let weightInPounds: Double
    let message: String
    let attitude: String
    let entryDate: Date
    let createdAt: Date

    // MARK: - Initializer

    init(
        id: String = UUID().uuidString,
        weightEntryID: String,
        weightInPounds: Double,
        message: String,
        attitude: String,
        entryDate: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.weightEntryID = weightEntryID
        self.weightInPounds = weightInPounds
        self.message = message
        self.attitude = attitude
        self.entryDate = entryDate
        self.createdAt = createdAt
    }

    // MARK: - Public Helpers

    /// Formatted weight string.
    var formattedWeight: String {
        String(format: "%.1f lbs", weightInPounds)
    }
}
