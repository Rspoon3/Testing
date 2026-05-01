import Foundation

// MARK: - Base Response Structure
struct GrafanaResponse: Codable {
    let results: [String: GrafanaResult]
}

struct GrafanaResult: Codable {
    let frames: [DataFrame]
    let refId: String?
    let dataframes: [String]?
}

// MARK: - DataFrame Structure
struct DataFrame: Codable {
    let schema: DataFrameSchema?
    let data: DataFrameData?
}

struct DataFrameSchema: Codable {
    let name: String?
    let refId: String?
    let fields: [Field]
    let meta: Meta?
}

struct Field: Codable {
    let name: String
    let type: String
    let typeInfo: TypeInfo?
    let config: FieldConfig?
    let labels: [String: String]?
}

struct TypeInfo: Codable {
    let frame: String?
    let nullable: Bool?
}

struct FieldConfig: Codable {
    let displayNameFromDS: String?
    let custom: CustomConfig?
}

struct CustomConfig: Codable {
    let displayMode: String?
    let showPoints: String?
}

struct Meta: Codable {
    let executedQueryString: String?
    let custom: MetaCustom?
    let sql: MetaSQL?
    let typeVersion: [Int]?
}

struct MetaCustom: Codable {
    let sql: String?
}

struct MetaSQL: Codable {
    let db: String?
    let schema: String?
    let table: String?
    let columns: [SQLColumn]?
}

struct SQLColumn: Codable {
    let name: String?
    let type: String?
}

struct DataFrameData: Codable {
    let values: [[AnyCodableValue]]
    let nanos: [Int]?
}

// MARK: - Helper Type for Any Value
enum AnyCodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let array = try? container.decode([AnyCodableValue].self) {
            self = .array(array)
        } else if let dict = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(dict)
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Cannot decode value"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        }
    }
    
    func stringValue() throws -> String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        default:
            throw DecodingError.typeMismatch(String.self, .init(codingPath: [], debugDescription: "Expected String"))
        }
    }
    
    func intValue() throws -> Int {
        switch self {
        case .int(let value):
            return value
        case .double(let value):
            return Int(value)
        case .string(let value):
            guard let int = Int(value) else {
                throw DecodingError.typeMismatch(Int.self, .init(codingPath: [], debugDescription: "Cannot convert to Int"))
            }
            return int
        default:
            throw DecodingError.typeMismatch(Int.self, .init(codingPath: [], debugDescription: "Expected Int"))
        }
    }
    
    func doubleValue() throws -> Double {
        switch self {
        case .double(let value):
            return value
        case .int(let value):
            return Double(value)
        case .string(let value):
            guard let double = Double(value) else {
                throw DecodingError.typeMismatch(Double.self, .init(codingPath: [], debugDescription: "Cannot convert to Double"))
            }
            return double
        default:
            throw DecodingError.typeMismatch(Double.self, .init(codingPath: [], debugDescription: "Expected Double"))
        }
    }
}

// MARK: - Error Types
enum ParsingError: LocalizedError {
    case invalidDataStructure
    case missingRequiredField
    case noResultsFound
    case noFramesFound
    case insufficientData
    
    var errorDescription: String? {
        switch self {
        case .invalidDataStructure:
            return "Invalid data structure in response"
        case .missingRequiredField:
            return "Missing required field in response"
        case .noResultsFound:
            return "No results found in response"
        case .noFramesFound:
            return "No data frames found in response"
        case .insufficientData:
            return "Insufficient data in response"
        }
    }
}