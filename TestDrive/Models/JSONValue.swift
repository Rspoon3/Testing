//
//  JSONValue.swift
//  TestDrive
//

import Foundation

/// A typed representation of a JSON value used to round-trip arbitrary settings files
/// without losing unknown keys.
enum JSONValue: Hashable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])
}

// MARK: - Codable

extension JSONValue: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognised JSON value"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }
}

// MARK: - Convenience

extension JSONValue {
    /// Returns the object backing this value, or an empty dictionary if it is not an object.
    var asObject: [String: JSONValue] {
        if case .object(let value) = self { return value }
        return [:]
    }

    /// Returns the array backing this value, or an empty array if it is not an array.
    var asArray: [JSONValue] {
        if case .array(let value) = self { return value }
        return []
    }

    var asString: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var asBool: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }
}
