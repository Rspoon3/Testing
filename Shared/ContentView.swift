//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.dismissSearch) var dismissSearch
    @AppStorage("locale") private var locale: Locale = Locale.current
    @State private var numberInput: String = "1234567.89"
    @State private var searchText = ""
    @State private var isPresented = false
    private var exampleDate: Date = Date()
    
    private var exampleNumber: Double {
        Double(numberInput) ?? -1
    }
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return Locale.availableIdentifiers
        } else {
            return Locale.availableIdentifiers.filter { id in
                let locale = Locale(identifier: id)
                let name = Locale.current.localizedString(forIdentifier: locale.identifier) ?? ""
                return name.localizedCaseInsensitiveContains(searchText) || id.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isPresented {
                    List(searchResults, id: \.self) { identifier in
                        Button {
                            locale = .init(identifier: identifier)
                            isPresented = false
                        } label: {
                            if let name = Locale.current.localizedString(forIdentifier: identifier) {
                                LabeledContent(name, value: identifier)
                            } else {
                                Text(identifier)
                            }
                        }
                    }
                    .lineLimit(1)
                } else {
                    Form {
                        Section {
                            LabeledContent("Locale", value: Locale.current.localizedString(forIdentifier: locale.identifier) ?? "")
                            LabeledContent("Locale ID", value: locale.identifier)
                            LabeledContent("Date", value: exampleDate.formatted(.dateTime.locale(locale)))
                        }
                        
                        Section("Number") {
                            TextField("Enter number", text: $numberInput)
                                 .keyboardType(.decimalPad)
                                 .textFieldStyle(.roundedBorder)
                            
                            LabeledContent("Number", value: exampleNumber.formatted(.number.locale(locale)))
                            LabeledContent("Compact Name", value: exampleNumber.formatted(.number.notation(.compactName).locale(locale)))
                            LabeledContent("Scientific", value: exampleNumber.formatted(.number.notation(.scientific).locale(locale)))
                            LabeledContent("Percent", value: exampleNumber.formatted(.percent.locale(locale)))
                            LabeledContent("Ordinal", value: Int(exampleNumber).formatted(.ordinal.locale(locale)))
                        }

                        if let code = locale.currency?.identifier {
                            Section("Currency") {
                                LabeledContent("Currency", value: exampleNumber.formatted(.currency(code: code)))
                                LabeledContent("Currency Full Name", value: exampleNumber.formatted(.currency(code: code).presentation(.fullName)))
                            }
                        }
                    }
                }
            }
            .font(.system(.body, design: .monospaced))
            .navigationTitle("Locale Formatter")
            .searchable(
                text: $searchText,
                isPresented: $isPresented,
                prompt: "Search for a locale"
            )
        }
    }
}

#Preview {
    ContentView()
}
