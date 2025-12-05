import Foundation

/// The type of daily summary.
enum SummaryType: String, Codable, Hashable {
    case morning
    case evening
}

/// A persisted message generated for a daily summary.
struct DailySummaryMessage: Codable, Identifiable, Hashable {
    let id: String
    let summaryType: SummaryType
    let message: String
    let attitudes: String
    let summaryDate: Date
    let createdAt: Date

    // MARK: - Initializer

    init(
        id: String = UUID().uuidString,
        summaryType: SummaryType,
        message: String,
        attitudes: String,
        summaryDate: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.summaryType = summaryType
        self.message = message
        self.attitudes = attitudes
        self.summaryDate = summaryDate
        self.createdAt = createdAt
    }

    // MARK: - Public Helpers

    /// The display title for the summary type.
    var title: String {
        switch summaryType {
        case .morning:
            return "Morning Summary"
        case .evening:
            return "Evening Summary"
        }
    }

    /// The SF Symbol name for the summary type.
    var symbolName: String {
        switch summaryType {
        case .morning:
            return "sunrise.fill"
        case .evening:
            return "moon.stars.fill"
        }
    }
}
