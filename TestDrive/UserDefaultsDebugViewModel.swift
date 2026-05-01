//
//  UserDefaultsDebugViewModel.swift
//  TestDrive
//
//  Created by Assistant on 8/26/25.
//

import SwiftUI
import Combine

final class UserDefaultsDebugViewModel: ObservableObject {
    @Published var userDefaultsItems: [(key: String, value: Any)] = []
    @Published var searchText: String = ""
    @Published var editableValues: [String: Any] = [:]
    @Published var pinnedKeys: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let pinnedKeysStorageKey = "__UserDefaultsDebugView_pinnedKeys"
    
    /// List of known built-in UserDefaults keys
    private let builtInKeys: Set<String> = [
        "AKLastIDMSEnvironment",
        "AddingEmojiKeybordHandled",
        "NSInterfaceStyle",
        "NSHyphenatesAsLastResort",
        "NSUsesCFStringTokenizerForLineBreaks",
        "AppleKeyboards",
        "AppleKeyboardsExpanded",
        "AppleLanguages",
        "AppleLanguagesSchemaVersion",
        "ApplePasscodeKeyboards",
        "AKLastLocale",
        "AppleLocale",
        "PKLogNotificationServiceResponsesKey",
        "NSUsesTextStylesForLineBreaks",
        "NSLanguages",
        "NSVisualBidiSelectionEnabled",
        "METAL_DEBUG_ERROR_MODE",
        "METAL_DEVICE_WRAPPER_TYPE",
        "METAL_ERROR_CHECK_EXTENDED_MODE",
        "METAL_ERROR_MODE",
        "METAL_WARNING_MODE",
    ]
    
    var filteredItems: [(key: String, value: Any)] {
        // Use editableValues to show current edited values, not original values
        let items = userDefaultsItems.map { item in
            let editedValue = editableValues[item.key]
            let finalValue = editedValue ?? item.value
            return (key: item.key, value: finalValue)
        }
        
        let filtered = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? items
            : items.filter { 
                $0.key.localizedCaseInsensitiveContains(searchText) ||
                String(describing: $0.value).localizedCaseInsensitiveContains(searchText)
            }
        let result = filtered.sorted { $0.key < $1.key }
        return result
    }
    
    var pinnedItems: [(key: String, value: Any)] {
        filteredItems.filter { pinnedKeys.contains($0.key) }
    }
    
    var unpinnedItems: [(key: String, value: Any)] {
        filteredItems.filter { !pinnedKeys.contains($0.key) }
    }
    
    // MARK: - Public
    
    func loadUserDefaults() {
        userDefaultsItems = userDefaults.dictionaryRepresentation()
            .filter { !$0.key.hasPrefix("__UserDefaultsDebugView_") }
            .filter { !builtInKeys.contains($0.key) }
            .map { ($0.key, $0.value) }
        
        editableValues = userDefaultsItems.reduce(into: [:]) { result, item in
            result[item.key] = item.value
        }
    }
    
    func loadPinnedKeys() {
        guard let savedPins = userDefaults.array(forKey: pinnedKeysStorageKey) as? [String] else { return }
        pinnedKeys = Set(savedPins)
    }
    
    func savePinnedKeys() {
        userDefaults.set(Array(pinnedKeys), forKey: pinnedKeysStorageKey)
    }
    
    func updateValue(_ newValue: Any, forKey key: String) {
        // Save to editableValues
        editableValues[key] = newValue
        
        // Save to UserDefaults
        userDefaults.set(newValue, forKey: key)
        
        // Update the specific item in userDefaultsItems to trigger UI update
        if let index = userDefaultsItems.firstIndex(where: { $0.key == key }) {
            userDefaultsItems[index] = (key: key, value: newValue)
        }
        
        // Force UI update
        objectWillChange.send()
    }
    
    func deleteItem(withKey key: String) {
        userDefaults.removeObject(forKey: key)
        pinnedKeys.remove(key)
        savePinnedKeys()
        loadUserDefaults()
    }
    
    func togglePin(forKey key: String) {
        withAnimation {
            if pinnedKeys.contains(key) {
                pinnedKeys.remove(key)
            } else {
                pinnedKeys.insert(key)
            }
            savePinnedKeys()
        }
    }
    
    func isPinned(key: String) -> Bool {
        pinnedKeys.contains(key)
    }
}
