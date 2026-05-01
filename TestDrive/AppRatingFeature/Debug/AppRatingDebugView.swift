//
//  AppRatingDebugView.swift
//  AppRatingFeature
//
//  Created on 9/25/25.
//

#if DEBUG
import SwiftUI

/// Debug view showing app rating eligibility status
public struct AppRatingDebugView: View {
    @State private var status: AppRatingEligibilityStatus?
    @State private var showingTestPrompt = false

    private let eligibilityRepository: AppRatingEligibilityRepository
    private let userStore: AppRatingUserStore
    private let viewedStore: AppRatingViewedStore
    private let useCase: PresentAppRatingAskToAskUseCase

    public init(
        eligibilityRepository: AppRatingEligibilityRepository,
        userStore: AppRatingUserStore,
        viewedStore: AppRatingViewedStore,
        useCase: PresentAppRatingAskToAskUseCase
    ) {
        self.eligibilityRepository = eligibilityRepository
        self.userStore = userStore
        self.viewedStore = viewedStore
        self.useCase = useCase
    }

    public var body: some View {
        List {
            Section("Eligibility Status") {
                if let status {
                    HStack {
                        Text("Eligible")
                        Spacer()
                        Image(systemName: status.isEligible ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(status.isEligible ? .green : .red)
                    }

                    if !status.ineligibilityReasons.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ineligibility Reasons:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ForEach(Array(status.ineligibilityReasons).sorted { $0.rawValue < $1.rawValue }, id: \.self) { reason in
                                Text("• \(reason.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }

            Section("User Statistics") {
                if let status {
                    LabeledContent("Number of Launches", value: "\(status.numberOfLaunches)")
                    LabeledContent("Number of Activations", value: "\(status.numberOfActivations)")
                    LabeledContent("Days Since Last Prompt", value: status.daysSinceLastPrompt.map { "\($0)" } ?? "Never shown")
                    LabeledContent("Times Shown This Year", value: "\(status.timesShownThisYear)")
                    LabeledContent("Rated Current Version", value: status.hasRatedCurrentVersion ? "Yes" : "No")
                }
            }

            Section("Requirements") {
                LabeledContent("Min Games", value: "3")
                LabeledContent("Min Launches", value: "1")
                LabeledContent("Cooldown Period", value: "30 days")
                LabeledContent("Max Per Year", value: "3 times")
            }

            Section("Debug Controls") {
                Toggle("Debug Override", isOn: Binding(
                    get: { userStore.debugOverrideEnabled },
                    set: { newValue in
                        if let mutableStore = userStore as? AppRatingUserStoreLive {
                            mutableStore.debugOverrideEnabled = newValue
                            refreshStatus()
                        }
                    }
                ))

                Button("Test Prompt (Force)") {
                    if useCase.forceShouldPresent() {
                        showingTestPrompt = true
                    }
                }
                .foregroundColor(.blue)

                Button("Clear All Data", role: .destructive) {
                    viewedStore.clearAll()
                    refreshStatus()
                }
            }

            Section("Raw Data") {
                LabeledContent("Total Launches", value: "\(userStore.numberOfLaunches)")
                LabeledContent("Total Activations", value: "\(userStore.numberOfActivations)")

                if !viewedStore.viewedHistory.isEmpty {
                    VStack(alignment: .leading) {
                        Text("View History:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(viewedStore.viewedHistory, id: \.self) { date in
                            Text(date.formatted())
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let lastRatedVersion = viewedStore.lastRatedVersion {
                    LabeledContent("Last Rated Version", value: lastRatedVersion)
                }
            }
        }
        .navigationTitle("App Rating Debug")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshStatus()
        }
        .overlay {
            if showingTestPrompt {
                AppRatingAskToAskView(
                    analytics: ConsoleAppRatingAnalyticsRecorder(),
                    useCase: useCase,
                    onDismiss: {
                        showingTestPrompt = false
                    }
                )
            }
        }
    }

    private func refreshStatus() {
        status = eligibilityRepository.eligibilityStatus
    }
}
#endif
