import Foundation

/// Manages user preferences stored in UserDefaults.
final class UserPreferences {
    static let shared = UserPreferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let selectedAttitudes = "selectedAttitudes"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastFetchTimestamp = "lastFetchTimestamp"
    }

    // MARK: - Properties

    /// The user's selected attitudes for AI messages.
    var selectedAttitudes: Set<Attitude> {
        get {
            guard let rawValues = defaults.stringArray(forKey: Keys.selectedAttitudes) else {
                return [.encouraging]
            }
            let attitudes = rawValues.compactMap { Attitude(rawValue: $0) }
            return attitudes.isEmpty ? [.encouraging] : Set(attitudes)
        }
        set {
            let rawValues = newValue.map(\.rawValue)
            defaults.set(rawValues, forKey: Keys.selectedAttitudes)
        }
    }

    /// Returns a random attitude from the selected set.
    var randomSelectedAttitude: Attitude {
        selectedAttitudes.randomElement() ?? .encouraging
    }

    /// Whether the user has completed onboarding.
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    /// Timestamp of the last HealthKit fetch.
    var lastFetchTimestamp: Date? {
        get { defaults.object(forKey: Keys.lastFetchTimestamp) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastFetchTimestamp) }
    }

    // MARK: - Initializer

    private init() {}
}
