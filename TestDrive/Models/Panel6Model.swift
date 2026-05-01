import Foundation

// Panel 6: Adoption Rate
struct AdoptionRateData: Codable {
    let timestamp: Date
    let version: String
    let adoptionRate: Double // Stored as percentage (0-100)
    
    init(from values: [AnyCodableValue]) throws {
        guard values.count >= 3 else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Insufficient values"))
        }
        let timeInterval = try values[0].doubleValue() / 1000.0
        self.timestamp = Date(timeIntervalSince1970: timeInterval)
        self.version = try values[1].stringValue()
        // The value is already a percentage (e.g., 70.86 for 70.86%)
        self.adoptionRate = try values[2].doubleValue()
    }
}