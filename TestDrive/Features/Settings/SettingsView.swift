import SwiftUI
import SFSymbols

/// Settings screen for changing app preferences.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()
    @State private var showingDebugLogs = false

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

                if #available(iOS 26, *) {
                    Section {
                        Picker(selection: $viewModel.selectedAIProvider) {
                            ForEach(AIProvider.allCases.filter(\.isAvailable)) { provider in
                                HStack {
                                    Image(symbol: provider.symbol)
                                    Text(provider.displayName)
                                }
                                .tag(provider)
                            }
                        } label: {
                            Label("AI Provider", symbol: .cpuFill)
                        }
                        .onChange(of: viewModel.selectedAIProvider) {
                            viewModel.saveAIProvider()
                        }
                    } header: {
                        Text("AI Provider")
                    } footer: {
                        Text(viewModel.selectedAIProvider == .chatGPT
                             ? "ChatGPT requires an internet connection."
                             : "Foundation Model runs entirely on-device.")
                    }
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

                    Button {
                        showingDebugLogs = true
                    } label: {
                        Label("View Debug Logs", symbol: .docText)
                    }

                    Button(role: .destructive) {
                        viewModel.clearSavedMessages()
                    } label: {
                        Label("Clear All Messages", symbol: .trash)
                    }
                } header: {
                    Text("Debug")
                } footer: {
                    Text("View debug logs to diagnose issues with HealthKit observers and notifications.")
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
            .sheet(isPresented: $showingDebugLogs) {
                DebugLogView()
            }
        }
    }
}

#Preview {
    SettingsView()
}
