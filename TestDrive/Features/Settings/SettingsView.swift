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
                    Toggle(isOn: $viewModel.morningSummaryEnabled) {
                        Label("Morning Summary", symbol: .sunMax)
                    }
                    .onChange(of: viewModel.morningSummaryEnabled) {
                        viewModel.saveNotificationSettings()
                    }

                    if viewModel.morningSummaryEnabled {
                        Picker("Time", selection: $viewModel.morningSummaryHour) {
                            ForEach(5..<12, id: \.self) { hour in
                                Text(viewModel.formatHour(hour)).tag(hour)
                            }
                        }
                        .onChange(of: viewModel.morningSummaryHour) {
                            viewModel.saveNotificationSettings()
                        }
                    }

                    Toggle(isOn: $viewModel.eveningSummaryEnabled) {
                        Label("Evening Summary", symbol: .moonStars)
                    }
                    .onChange(of: viewModel.eveningSummaryEnabled) {
                        viewModel.saveNotificationSettings()
                    }

                    if viewModel.eveningSummaryEnabled {
                        Picker("Time", selection: $viewModel.eveningSummaryHour) {
                            ForEach(17..<24, id: \.self) { hour in
                                Text(viewModel.formatHour(hour)).tag(hour)
                            }
                        }
                        .onChange(of: viewModel.eveningSummaryHour) {
                            viewModel.saveNotificationSettings()
                        }
                    }
                } header: {
                    Text("Daily Summaries")
                } footer: {
                    Text("Get AI-generated summaries of your fitness activity.")
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
                        Label("Saved Messages", symbol: .bubbleLeftFill)
                        Spacer()
                        Text("\(viewModel.savedMessagesCount)")
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        viewModel.clearSavedMessages()
                    } label: {
                        Label("Clear All Messages", symbol: .trash)
                    }
                } header: {
                    Text("Debug")
                } footer: {
                    Text("Clear all saved messages to reprocess workouts and receive new notifications.")
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
