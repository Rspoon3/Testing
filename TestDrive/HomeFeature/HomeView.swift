//
//  HomeView.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/14/25.
//

import SwiftUI
import SwiftTools

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Namespace private var skipAnimation
    private let requester = HealthKitRequester()
    @State private var selectedMetric: MetricType?
    
    @State private var blockStatus: [BlockMode: Bool] = [
        .steps: false,
        .rings: true,
        .mindfulness: false
    ]
    
    
    // Placeholder apps
    let mockApps: [String] = ["📱", "🎮", "📸", "📺", "🛍", "🎵", "💬", "📷"]
    let columns = [GridItem(.adaptive(minimum: 60))]
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        ScrollView {
            VStack(spacing: 32) {
                glassyContainer { blockingApps }
                glassyContainer { blockingOptions }
                glassyContainer { skipOptions }
                glassyContainer { progressSection }
            }
            .padding(.horizontal)
        }
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.4), .purple.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .sensoryFeedback(.selection, trigger: viewModel.selectedBlockModes)
        .sensoryFeedback(.selection, trigger: viewModel.skipOption)
        .navigationTitle("Earn It")
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.restoreFamilySelection()
        }
        .onAppear {
            Task {
                try? await requester.requestAuthorization()
                try? await viewModel.evaluateProgressAndShieldApps()
            }
        }
        .familyActivityPicker(
            isPresented: $viewModel.showPicker,
            selection: $viewModel.familyActivitySelection
        )
        .sheet(item: $selectedMetric) { metric in
            GoalEditorSheet(metric: metric) { newGoal in
                switch metric {
                case .steps:
                    viewModel.stepGoal = newGoal
                case .mindfulness:
                    viewModel.mindfulnessGoal = newGoal
                }
            }
        }
    }
    
    @ViewBuilder
    func glassyContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var blockingApps: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Blocked Apps")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(viewModel.savedAppTokens), id: \.self) { token in
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 60, height: 60)
                            
                            Label(token)
                                .labelStyle(.iconOnly)
                                .scaleEffect(1.75)
                        }
                        
                        Label(token)
                            .labelStyle(.titleOnly)
                            .scaleEffect(0.5)
                    }
                }
                
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 60, height: 60)
                        Image(symbol: .plus)
                            .font(.largeTitle)
                    }
                    Text("Add")
                        .scaleEffect(0.5)
                }
                .onTapGesture {
                    viewModel.showPicker = true
                }
            }
        }
    }
    
    private var blockingOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Blocking Conditions")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            FlowLayout(alignment: .leading) {
                ForEach(BlockMode.allCases, id: \.self) { mode in
                    VStack {
                        Button {
                            viewModel.toggleBlockMode(mode)
                        } label: {
                            Label(mode.label, systemImage: mode.icon)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedBlockModes.contains(mode) ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        // Status text
                        if viewModel.selectedBlockModes.contains(mode) {
                            Text(blockStatus[mode] == true ? "✓ Completed" : "Not Yet")
                                .font(.caption)
                                .foregroundColor(blockStatus[mode] == true ? .green : .secondary)
                        } else {
                            Text("Not Enabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var skipOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Skip Blocking")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            FlowLayout(alignment: .leading) {
                ForEach(SkipOption.allCases, id: \.self) { option in
                    Button {
                        Task {
                            await viewModel.skipOptionSelected(option)
                        }
                    } label: {
                        ZStack {
                            if viewModel.skipOption == option {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.blue.opacity(0.1))
                                    .matchedGeometryEffect(id: "skipHighlight", in: skipAnimation)
                            }
                            
                            Label(option.label, systemImage: option.icon)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .foregroundColor(.primary)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.clear)
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .top, spacing: 16) {
                if let steps = viewModel.metrics.stepCount {
                    CircularProgressView(
                        progress: Double(steps) / Double(viewModel.stepGoal),
                        title: "Steps",
                        valueText: "\(steps.formatted())/\(viewModel.stepGoal.formatted(.number.notation(.compactName)))",
                        systemImage: "figure.walk"
                    )
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        selectedMetric = .steps
                    }
                }
                
                if let mindfulnessMinutes = viewModel.metrics.mindfulnessMinutes {
                    CircularProgressView(
                        progress: Double(mindfulnessMinutes) / Double(viewModel.mindfulnessGoal),
                        title: "Mindful",
                        valueText: "\(mindfulnessMinutes.formatted())/\(viewModel.mindfulnessGoal.formatted(.number.notation(.compactName)))",
                        systemImage: "brain.head.profile"
                    )
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        selectedMetric = .mindfulness
                    }
                }
                
                if let summary = viewModel.metrics.ringValues?.summary {
                    ActivityRingViewRepresentable(summary: summary)
                        .frame(width: 50, height: 50)
                        .frame(maxWidth: .infinity)
                }
            }
            .animation(.default, value: viewModel.metrics)
        }
    }
}


#Preview {
    NavigationStack {
        HomeView()
            .navigationTitle("Home")
    }
}


struct GoalEditorSheet: View {
    var metric: MetricType
    var onSave: (Int) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var newGoal: Double = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section("Set your goal") {
                    TextField("Goal", value: $newGoal, format: .number)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(metric.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(Int(newGoal))
                        dismiss()
                    }
                }
            }
        }
    }
}

enum MetricType: Identifiable {
    var id: Self { self }
    case steps
    case mindfulness
    
    var title: String {
        switch self {
        case .steps: return "Steps Goal"
        case .mindfulness: return "Mindfulness Goal"
        }
    }
    
    var systemImage: String {
        switch self {
        case .steps: return "figure.walk"
        case .mindfulness: return "brain.head.profile"
        }
    }
}
