import SwiftUI
import SFSymbols

/// Settings screen for changing app preferences.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AttitudePickerView(selectedAttitudes: $viewModel.selectedAttitudes)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .onChange(of: viewModel.selectedAttitudes) {
                            viewModel.saveAttitudes()
                        }
                } header: {
                    Text("Your Buddy's Vibes")
                } footer: {
                    Text("Select one or more vibes. Your buddy will randomly pick from your selections after each workout.")
                }

                Section {
                    HStack {
                        Label("Version", symbol: .infoCircle)
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }

                Section {
                    HStack {
                        Label("Processed Workouts", symbol: .checkmarkCircle)
                        Spacer()
                        Text("\(viewModel.processedWorkoutsCount)")
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        viewModel.clearProcessedWorkouts()
                    } label: {
                        Label("Clear Processed Workouts", symbol: .trash)
                    }
                } header: {
                    Text("Debug")
                } footer: {
                    Text("Clear the processed workouts list to receive notifications for workouts again.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
