//
//  LoginView.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import SwiftUI

/// View for user authentication.
struct LoginView: View {
    @Bindable private var viewModel: LoginViewModel

    // MARK: - Initializer

    /// Creates a login view.
    /// - Parameter viewModel: The view model managing login state.
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $viewModel.name)
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Button { viewModel.login() } label: {
                        Text("Login")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(viewModel.name.isEmpty || viewModel.email.isEmpty)
                }
            }
            .navigationTitle("Login")
        }
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel(factory: RootFactory()))
}
