//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

/// Main view demonstrating the locks and keys pattern with factories.
struct ContentView: View {
    @Environment(\.factory) private var factory
    @State private var loginViewModel: LoginViewModel?

    // MARK: - Body

    var body: some View {
        Group {
            if let userBoundFactory = loginViewModel?.userBoundFactory {
                TabView {
                    NavigationStack {
                        ProfileView(viewModel: userBoundFactory.makeProfileViewModel())
                    }
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }

                    NavigationStack {
                        OrderHistoryView(viewModel: userBoundFactory.makeOrderHistoryViewModel())
                    }
                    .tabItem {
                        Label("Orders", systemImage: "shippingbox.fill")
                    }

                    NavigationStack {
                        SettingsView(viewModel: userBoundFactory.makeSettingsViewModel())
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }

                    NavigationStack {
                        logoutView
                    }
                    .tabItem {
                        Label("Logout", systemImage: "arrow.right.square")
                    }
                }
            } else {
                LoginView(viewModel: loginViewModel ?? factory.makeLoginViewModel())
                    .onAppear {
                        if loginViewModel == nil {
                            loginViewModel = factory.makeLoginViewModel()
                        }
                    }
            }
        }
    }

    // MARK: - Private Views

    private var logoutView: some View {
        VStack {
            Text("Are you sure you want to logout?")
                .font(.headline)
                .padding()

            Button { loginViewModel?.logout() } label: {
                Text("Logout")
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
        .navigationTitle("Logout")
    }
}

#Preview {
    ContentView()
}
