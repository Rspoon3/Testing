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
