import Foundation

// Panel 42: iOS Version Active Users
struct IOSVersionData: Codable {
    let iosVersion: String
    let countOfActiveUsers: Int
    
    init(from values: [AnyCodableValue]) throws {
        guard values.count >= 2 else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Insufficient values"))
        }
        self.iosVersion = try values[0].stringValue()
        self.countOfActiveUsers = try values[1].intValue()
    }
}