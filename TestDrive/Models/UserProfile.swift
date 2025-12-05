import Foundation
import HealthKit

/// User profile data from HealthKit.
struct UserProfile {
    let age: Int?
    let biologicalSex: HKBiologicalSex?
    let weightInPounds: Double?
    let heightInInches: Double?

    /// Formatted age string.
    var ageString: String? {
        guard let age else { return nil }
        return "\(age) years old"
    }

    /// Formatted biological sex string.
    var sexString: String? {
        guard let biologicalSex else { return nil }
        switch biologicalSex {
        case .male:
            return "male"
        case .female:
            return "female"
        case .other:
            return "other"
        case .notSet:
            return nil
        @unknown default:
            return nil
        }
    }

    /// Formatted weight string.
    var weightString: String? {
        guard let weightInPounds else { return nil }
        return "\(Int(weightInPounds)) lbs"
    }

    /// Formatted height string.
    var heightString: String? {
        guard let heightInInches else { return nil }
        let feet = Int(heightInInches) / 12
        let inches = Int(heightInInches) % 12
        return "\(feet)'\(inches)\""
    }

    /// Formats profile for inclusion in a prompt.
    func formatForPrompt() -> String {
        var parts: [String] = []

        if let age = ageString {
            parts.append(age)
        }

        if let sex = sexString {
            parts.append(sex)
        }

        if let height = heightString {
            parts.append(height)
        }

        if let weight = weightString {
            parts.append(weight)
        }

        guard !parts.isEmpty else {
            return "User profile: Not available"
        }

        return "User profile: " + parts.joined(separator: ", ")
    }
}
