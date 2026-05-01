//
//  UserDefaultsRowViewModel.swift
//  TestDrive
//
//  Created by Assistant on 8/26/25.
//

import SwiftUI

final class UserDefaultsRowViewModel: ObservableObject {
    let key: String
    private(set) var value: Any
    let isPinned: Bool
    let onValueChanged: (Any) -> Void
    
    @Published var editedStringValue: String = ""
    @Published var editedBoolValue: Bool = false
    @Published var editedNumberValue: String = ""
    @Published var editedArrayElements: [String] = []
    @Published var editedDateValue: Date = Date()
    
    // MARK: - Initializer
    
    init(key: String, value: Any, isPinned: Bool, onValueChanged: @escaping (Any) -> Void) {
        self.key = key
        self.value = value
        self.isPinned = isPinned
        self.onValueChanged = onValueChanged
        setupInitialValues()
    }
    
    // MARK: - Public
    
    func updateValue(_ newValue: Any) {
        if !valuesAreEqual(value, newValue) {
            self.value = newValue
            setupInitialValues()
        }
    }
    
    private func valuesAreEqual(_ value1: Any, _ value2: Any) -> Bool {
        if let val1 = value1 as? String, let val2 = value2 as? String {
            return val1 == val2
        } else if let val1 = value1 as? Bool, let val2 = value2 as? Bool {
            return val1 == val2
        } else if let val1 = value1 as? Int, let val2 = value2 as? Int {
            return val1 == val2
        } else if let val1 = value1 as? Double, let val2 = value2 as? Double {
            return val1 == val2
        } else if let val1 = value1 as? Float, let val2 = value2 as? Float {
            return val1 == val2
        } else if let val1 = value1 as? [Any], let val2 = value2 as? [Any] {
            return val1.count == val2.count && zip(val1, val2).allSatisfy { valuesAreEqual($0, $1) }
        }
        return false
    }
    
    var typeDescription: String {
        switch value {
        case is Bool:
            return "Boolean"
        case is String:
            return "String"
        case is Int:
            return "Integer"
        case is Double:
            return "Double"
        case is Float:
            return "Float"
        case is Data:
            return "Data (\((value as? Data)?.count ?? 0) bytes)"
        case is Date:
            return "Date"
        case is [Any]:
            return "Array (\((value as? [Any])?.count ?? 0) items)"
        case is [String: Any]:
            return "Dictionary (\((value as? [String: Any])?.count ?? 0) items)"
        default:
            return String(describing: type(of: value))
        }
    }
    
    var isEditable: Bool {
        switch value {
        case is Bool, is String, is Int, is Double, is Float, is [Any], is Date:
            return true
        default:
            return false
        }
    }
    
    func updateBoolValue(_ newValue: Bool) {
        editedBoolValue = newValue
        onValueChanged(newValue)
    }
    
    func updateStringValue(_ newValue: String) {
        editedStringValue = newValue
        onValueChanged(newValue)
    }
    
    func updateIntValue() {
        guard let intValue = Int(editedNumberValue) else { return }
        onValueChanged(intValue)
    }
    
    func updateDoubleValue() {
        guard let doubleValue = Double(editedNumberValue) else { return }
        
        if value is Float {
            onValueChanged(Float(doubleValue))
        } else {
            onValueChanged(doubleValue)
        }
    }
    
    func updateDateValue(_ newValue: Date) {
        editedDateValue = newValue
        onValueChanged(newValue)
    }
    
    func updateArrayFromEditedElements() {
        var newArray: [Any] = []
        
        for element in editedArrayElements {
            if let boolValue = Bool(element.lowercased()) {
                newArray.append(boolValue)
            } else if let intValue = Int(element) {
                newArray.append(intValue)
            } else if let doubleValue = Double(element) {
                newArray.append(doubleValue)
            } else {
                newArray.append(element)
            }
        }
        
        onValueChanged(newArray)
    }
    
    private func setupInitialValues() {
        switch value {
        case let boolValue as Bool:
            editedBoolValue = boolValue
        case let stringValue as String:
            editedStringValue = stringValue
        case let intValue as Int:
            editedNumberValue = String(intValue)
        case let doubleValue as Double:
            editedNumberValue = String(doubleValue)
        case let floatValue as Float:
            editedNumberValue = String(floatValue)
        case let arrayValue as [Any]:
            editedArrayElements = arrayValue.map { element in
                String(describing: element)
            }
        case let dateValue as Date:
            editedDateValue = dateValue
        default:
            break
        }
    }
}
