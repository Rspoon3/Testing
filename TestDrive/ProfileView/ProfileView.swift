//
//  ProfileView.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import SwiftUI

/// View displaying user profile information.
struct ProfileView: View {
    private let viewModel: ProfileViewModel

    // MARK: - Initializer

    /// Creates a profile view.
    /// - Parameter viewModel: The view model managing profile data.
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        List {
            Section("Profile Information") {
                LabeledContent("Name", value: viewModel.getUserName())
                LabeledContent("Email", value: viewModel.getUserEmail())
                LabeledContent("User ID", value: viewModel.getUserID())
            }
        }
        .navigationTitle("Profile")
    }
}

#Preview {
    NavigationStack {
        ProfileView(
            viewModel: ProfileViewModel(
                user: User(name: "John Doe", email: "john@example.com")
            )
        )
    }
}
