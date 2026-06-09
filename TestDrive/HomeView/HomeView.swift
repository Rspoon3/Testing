//
//  HomeView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 6/5/26.
//

import SwiftUI

/// The app's home screen, which runs a short countdown on appearance.
struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showsSettings = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            TimelineView(.animation) { context in
                let remaining = viewModel.remainingSeconds(at: context.date)

                countdown(remaining)
                    .onChange(of: remaining == 0) { _, isFinished in
                        if isFinished {
                            viewModel.timerDidFinish()
                        }
                    }
            }
            .overlay {
                if viewModel.showsIneligibleWarning {
                    ineligibleWarning
                }
            }
            .animation(.default, value: viewModel.showsIneligibleWarning)
            .onOpenURL { _ in
                viewModel.handleDeeplink()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showsSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showsSettings) {
                viewModel.settingsDidDismiss()
            } content: {
                SettingsView()
            }
        }
    }

    // MARK: - Private Views

    /// The red box shown when the user is not eligible for a referral.
    private var ineligibleWarning: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.red)
            .frame(width: 200, height: 200)
    }

    /// The large countdown label.
    /// - Parameter seconds: The seconds remaining to display, to hundredth precision.
    private func countdown(_ seconds: TimeInterval) -> some View {
        Text(String(format: "%.2f", seconds))
            .font(.system(size: 72, weight: .bold, design: .rounded))
            .monospacedDigit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HomeView()
}
