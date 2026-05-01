//
//  UserDefaultsDebugView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 8/26/25.
//

import SwiftUI

struct UserDefaultsDebugView: View {
    @StateObject private var viewModel = UserDefaultsDebugViewModel()
    
    var body: some View {
        NavigationView {
            List {
                if !viewModel.pinnedItems.isEmpty {
                    Section("Pinned") {
                        ForEach(viewModel.pinnedItems, id: \.key) { item in
                            UserDefaultsRowView(
                                key: item.key,
                                value: item.value,
                                isPinned: true,
                                onValueChanged: { newValue in
                                    viewModel.updateValue(newValue, forKey: item.key)
                                }
                            )
                            .swipeActions(edge: .leading) {
                                Button {
                                    viewModel.togglePin(forKey: item.key)
                                } label: {
                                    Label("Unpin", systemImage: "pin.slash")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteItem(withKey: item.key)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                Section("\(viewModel.pinnedItems.isEmpty ? "" : "All")") {
                    ForEach(viewModel.unpinnedItems, id: \.key) { item in
                        UserDefaultsRowView(
                            key: item.key,
                            value: item.value,
                            isPinned: false,
                            onValueChanged: { newValue in
                                viewModel.updateValue(newValue, forKey: item.key)
                            }
                        )
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.togglePin(forKey: item.key)
                            } label: {
                                Label("Pin", systemImage: "pin")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteItem(withKey: item.key)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .animation(.default, value: viewModel.searchText)
            .searchable(text: $viewModel.searchText, prompt: "Search keys or values")
            .navigationTitle("User Defaults")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadUserDefaults()
                viewModel.loadPinnedKeys()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
}
