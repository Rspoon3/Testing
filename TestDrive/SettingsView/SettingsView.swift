//
//  SettingsView.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import SwiftUI

/// View for managing user settings.
struct SettingsView: View {
    @Bindable private var viewModel: SettingsViewModel

    // MARK: - Initializer

    /// Creates a settings view.
    /// - Parameter viewModel: The view model managing settings state.
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        List {
            Section("User") {
                LabeledContent("Logged in as", value: viewModel.getUserName())
            }

            Section("Preferences") {
                Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                Toggle("Dark Mode", isOn: $viewModel.darkModeEnabled)
            }

            Section {
                Button { viewModel.saveSettings() } label: {
                    Text("Save Settings")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            viewModel: SettingsViewModel(
                user: User(name: "John Doe", email: "john@example.com")
            )
        )
    }
}
