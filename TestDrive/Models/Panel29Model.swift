import Foundation

// Panel 29: Weekly Active Users Distribution by iOS Version
struct WeeklyActiveUsersData: Codable, Identifiable {
    let id = UUID()
    let week: Date
    let iosVersion: String
    let shareOfUsers: Double // Percentage of users (0.0 to 1.0)
    
    init(week: Date, iosVersion: String, shareOfUsers: Double) {
        self.week = week
        self.iosVersion = iosVersion
        self.shareOfUsers = shareOfUsers
    }
    
    enum CodingKeys: String, CodingKey {
        case week, iosVersion, shareOfUsers
    }
    
    /// Convenience property to get percentage as 0-100
    var shareAsPercentage: Double {
        return shareOfUsers * 100
    }
    
    /// Display-friendly iOS version name
    var displayVersion: String {
        switch iosVersion {
        case "68G9Z0":
            return "Unknown"
        default:
            return "iOS \(iosVersion)"
        }
    }
}