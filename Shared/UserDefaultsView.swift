//
//  UserDefaultsView.swift
//  Testing
//
//  Created by Ricky on 1/6/25.
//

import SwiftUI

public struct UserDefaultsView: View {
    @FocusState private var focusedField: String?
    @State private var userDefaultsItems: [(key: String, value: Any)] = []
    @State private var searchText: String = ""
    @AppStorage("debug.UserDefaultsView.showCustomOnly") private var showCustomOnly: Bool = true
    let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

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
    
    private var filteredItems: [(key: String, value: Any)] {
        let customOnly = userDefaultsItems.filter { isCustomKey($0.key) }
        
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let items = showCustomOnly ? customOnly : userDefaultsItems
            return items.sorted {
                $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending
            }
        }
        
        let filtered = if showCustomOnly {
            customOnly.filter { $0.key.localizedCaseInsensitiveContains(searchText) }
        } else {
            userDefaultsItems.filter { $0.key.localizedCaseInsensitiveContains(searchText) }
        }
        
        return filtered.sorted {
            $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending
        }
    }
    
    public var body: some View {
        VStack {
            Toggle("Show Custom Keys Only", isOn: $showCustomOnly)
                .padding()
            
            TextField("Search", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
                .focused($focusedField, equals: "searchText")

            List {
                ForEach(filteredItems, id: \.key) { item in
                    HStack {
                        Text(item.key).bold()
                        Spacer()
                        getControl(for: item)
                    }
                }
            }
        }
        .onAppear(perform: loadUserDefaults)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
    
    private func loadUserDefaults() {
        let items: [(key: String, value: Any)] = userDefaults.dictionaryRepresentation().map { ($0.key, $0.value) }
        userDefaultsItems = items.sorted {
            $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending
        }
        
        for (key, value) in userDefaultsItems {
            print(key)
        }
    }
    
    /// Check if a key is custom by comparing against known built-in keys
    private func isCustomKey(_ key: String) -> Bool {
        return !builtInKeys.contains(key)
    }
    
    @ViewBuilder
    private func getControl(for item: (key: String, value: Any)) -> some View {
        if let boolValue = item.value as? Bool {
            Toggle("", isOn: Binding(
                get: { boolValue },
                set: { newValue in
                    userDefaults.set(newValue, forKey: item.key)
                    loadUserDefaults()
                }
            ))
        } else if let numberValue = item.value as? NSNumber {
            TextField(
                "",
                text: Binding(
                    get: { "\(numberValue)" },
                    set: { newValue in
                        if let doubleValue = Double(newValue) {
                            userDefaults.set(doubleValue, forKey: item.key)
                            loadUserDefaults()
                        }
                    }
                )
            )
            .focused($focusedField, equals: item.key)
            .keyboardType(item.value is Int ? .numberPad : .decimalPad)
            .frame(width: 100)
            .textFieldStyle(.roundedBorder)
        } else if let stringValue = item.value as? String {
            TextField(
                "",
                text: Binding(
                    get: { stringValue },
                    set: { newValue in
                        userDefaults.set(newValue, forKey: item.key)
                        loadUserDefaults()
                    }
                )
            )
            .focused($focusedField, equals: item.key)
            .frame(width: 200)
            .textFieldStyle(.roundedBorder)
        } else if let dateValue = item.value as? Date {
            // DatePicker for Date values
            VStack {
                Text(dateValue.description)
                DatePicker(
                    "",
                    selection: Binding(
                        get: { dateValue },
                        set: { newValue in
                            UserDefaults.standard.set(newValue, forKey: item.key)
                            loadUserDefaults()
                        }
                    )
                )
                .datePickerStyle(.compact)
            }
        } else {
            // Handle unsupported types gracefully
            VStack(alignment: .leading) {
                Text("Unsupported Type").foregroundColor(.gray)
                Text("Type: \(type(of: item.value))").font(.caption).foregroundColor(.secondary)
                Text("Value: \(String(describing: item.value))")
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button("Copy Value") {
                        UIPasteboard.general.string = "\(String(describing: item.value))"
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Delete") {
                        UserDefaults.standard.removeObject(forKey: item.key)
                        loadUserDefaults()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .frame(maxWidth: 300)
        }
    }
}
