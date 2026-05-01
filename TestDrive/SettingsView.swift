//
//  SettingsView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 9/24/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("maxTime") private var maxTime: Double = 30.0
    @AppStorage("debounceDelay") private var debounceDelay: Double = 10.0
    @AppStorage("deletionSpeed") private var deletionSpeed: Double = 1.0

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Timer Settings")) {
                    Stepper("Countdown Time: \(Int(maxTime)) seconds", value: $maxTime, in: 10...120, step: 5)

                    Stepper("Debounce Delay: \(Int(debounceDelay)) seconds", value: $debounceDelay, in: 1...30, step: 1)
                }

                Section(header: Text("Deletion Settings")) {
                    Stepper("Deletion Speed: \(deletionSpeed, specifier: "%.1f")x", value: $deletionSpeed, in: 0.5...5.0, step: 0.1)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
