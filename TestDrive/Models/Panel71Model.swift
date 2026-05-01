import Foundation

// Panel 71: Swift SLOC (Lines of Code)
struct SwiftSLOCData: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let linesOfCode: Double
    let field: String
    
    init(from values: [AnyCodableValue]) throws {
        guard values.count >= 3 else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Insufficient values"))
        }
        let timeInterval = try values[0].doubleValue() / 1000.0
        self.timestamp = Date(timeIntervalSince1970: timeInterval)
        self.linesOfCode = try values[1].doubleValue()
        self.field = try values[2].stringValue()
    }
    
    enum CodingKeys: String, CodingKey {
        case timestamp, linesOfCode, field
    }
}