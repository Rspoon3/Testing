//
//  SettingsView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 6/5/26.
//

import SwiftUI

/// A settings screen for choosing which user identifier is active.
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Picker("User ID", selection: $viewModel.selectedUserID) {
                    ForEach(viewModel.userIDs, id: \.self) { userID in
                        Text(userID).tag(userID)
                    }
                }
                .pickerStyle(.inline)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
