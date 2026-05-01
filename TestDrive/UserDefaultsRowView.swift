//
//  UserDefaultsRowView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 8/26/25.
//

import SwiftUI

struct UserDefaultsRowView: View {
    @StateObject private var viewModel: UserDefaultsRowViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    let key: String
    let value: Any
    let isPinned: Bool
    let onValueChanged: (Any) -> Void
    
    init(key: String, value: Any, isPinned: Bool, onValueChanged: @escaping (Any) -> Void) {
        self.key = key
        self.value = value
        self.isPinned = isPinned
        self.onValueChanged = onValueChanged
        _viewModel = StateObject(wrappedValue: UserDefaultsRowViewModel(
            key: key,
            value: value,
            isPinned: isPinned,
            onValueChanged: onValueChanged
        ))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        if viewModel.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        Text(viewModel.key)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    Text(viewModel.typeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if viewModel.isEditable {
                editableContent
            } else {
                displayContent
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            viewModel.updateValue(value)
        }
    }
    
    @ViewBuilder
    private var displayContent: some View {
        switch viewModel.value {
        case let boolValue as Bool:
            HStack {
                Circle()
                    .fill(boolValue ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(boolValue ? "true" : "false")
                    .font(.system(.body, design: .monospaced))
            }
        case let stringValue as String:
            Text(stringValue.isEmpty ? "(empty)" : stringValue)
                .font(.system(.body, design: .monospaced))
                .lineLimit(2)
                .truncationMode(.tail)
        case let dateValue as Date:
            Text(DateFormatter.localizedString(from: dateValue, dateStyle: .medium, timeStyle: .medium))
                .font(.system(.body, design: .monospaced))
        case let dataValue as Data:
            Text("\(dataValue.count) bytes")
                .font(.system(.body, design: .monospaced))
        case let dictValue as [String: Any]:
            Text("Dictionary with \(dictValue.count) items")
                .font(.system(.body, design: .monospaced))
        default:
            Text(String(describing: viewModel.value))
                .font(.system(.body, design: .monospaced))
                .lineLimit(2)
                .truncationMode(.tail)
        }
    }
    
    @ViewBuilder
    private var editableContent: some View {
        switch viewModel.value {
        case is Bool:
            Toggle("Value", isOn: $viewModel.editedBoolValue)
                .onChange(of: viewModel.editedBoolValue) { _, newValue in
                    viewModel.updateBoolValue(newValue)
                }
        case is String:
            TextField("Value", text: $viewModel.editedStringValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(.body, design: .monospaced))
                .focused($isTextFieldFocused)
                .onChange(of: isTextFieldFocused) { _, focused in
                    viewModel.updateStringValue(viewModel.editedStringValue)
                }
                .onSubmit {
                    viewModel.updateStringValue(viewModel.editedStringValue)
                    isTextFieldFocused = false
                }
        case is Int:
            TextField("Value", text: $viewModel.editedNumberValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .font(.system(.body, design: .monospaced))
                .focused($isTextFieldFocused)
                .onChange(of: isTextFieldFocused) { _, focused in
                    viewModel.updateIntValue()
                }
                .onSubmit {
                    viewModel.updateIntValue()
                    isTextFieldFocused = false
                }
        case is Double, is Float:
            TextField("Value", text: $viewModel.editedNumberValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .font(.system(.body, design: .monospaced))
                .focused($isTextFieldFocused)
                .onChange(of: isTextFieldFocused) { _, focused in
                    viewModel.updateDoubleValue()
                }
                .onSubmit {
                    viewModel.updateDoubleValue()
                    isTextFieldFocused = false
                }
        case is Date:
            DatePicker("Date", selection: $viewModel.editedDateValue, displayedComponents: [.date, .hourAndMinute])
                .onChange(of: viewModel.editedDateValue) { _, newValue in
                    viewModel.updateDateValue(newValue)
                }
        case is [Any]:
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<viewModel.editedArrayElements.count, id: \.self) { index in
                    HStack {
                        Text("[\(index)]")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        
                        TextField("Value", text: $viewModel.editedArrayElements[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                            .focused($isTextFieldFocused)
                            .onChange(of: isTextFieldFocused) { _, focused in
                                viewModel.updateArrayFromEditedElements()
                            }
                            .onSubmit {
                                viewModel.updateArrayFromEditedElements()
                                isTextFieldFocused = false
                            }
                    }
                }
            }
        default:
            EmptyView()
        }
    }
}
