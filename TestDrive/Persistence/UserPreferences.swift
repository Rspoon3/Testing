import Foundation

/// Manages user preferences stored in UserDefaults.
final class UserPreferences {
    static let shared = UserPreferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let selectedAttitudes = "selectedAttitudes"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastFetchTimestamp = "lastFetchTimestamp"
        static let morningSummaryHour = "morningSummaryHour"
        static let eveningSummaryHour = "eveningSummaryHour"
        static let morningSummaryEnabled = "morningSummaryEnabled"
        static let eveningSummaryEnabled = "eveningSummaryEnabled"
        static let selectedAIProvider = "selectedAIProvider"
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

    /// Hour for morning summary notification (0-23). Default: 8 AM.
    var morningSummaryHour: Int {
        get {
            let value = defaults.integer(forKey: Keys.morningSummaryHour)
            return value == 0 && !defaults.bool(forKey: Keys.morningSummaryHour + "_set") ? 8 : value
        }
        set {
            defaults.set(newValue, forKey: Keys.morningSummaryHour)
            defaults.set(true, forKey: Keys.morningSummaryHour + "_set")
        }
    }

    /// Hour for evening summary notification (0-23). Default: 9 PM.
    var eveningSummaryHour: Int {
        get {
            let value = defaults.integer(forKey: Keys.eveningSummaryHour)
            return value == 0 && !defaults.bool(forKey: Keys.eveningSummaryHour + "_set") ? 21 : value
        }
        set {
            defaults.set(newValue, forKey: Keys.eveningSummaryHour)
            defaults.set(true, forKey: Keys.eveningSummaryHour + "_set")
        }
    }

    /// Whether morning summary notifications are enabled. Default: true.
    var morningSummaryEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.morningSummaryEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.morningSummaryEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.morningSummaryEnabled) }
    }

    /// Whether evening summary notifications are enabled. Default: true.
    var eveningSummaryEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.eveningSummaryEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.eveningSummaryEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.eveningSummaryEnabled) }
    }

    /// The user's selected AI provider. Default: .chatGPT.
    var selectedAIProvider: AIProvider {
        get {
            guard let rawValue = defaults.string(forKey: Keys.selectedAIProvider),
                  let provider = AIProvider(rawValue: rawValue) else {
                return .chatGPT
            }
            return provider
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.selectedAIProvider) }
    }

    // MARK: - Initializer

    private init() {}
}
