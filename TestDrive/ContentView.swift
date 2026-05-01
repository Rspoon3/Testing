import SwiftUI

enum ChartType: String, CaseIterable {
    case iosVersion = "iOS Version Distribution"
    case swiftSLOC = "Swift Lines of Code"
    case adoptionRate = "Version Adoption Rate"
    case weeklyActiveUsers = "Weekly Active Users by iOS Version"
    
    var displayName: String {
        return self.rawValue
    }
}

struct ContentView: View {
    @State private var iosVersionData: [IOSVersionData] = []
    @State private var swiftSLOCData: [SwiftSLOCData] = []
    @State private var adoptionRateData: [AdoptionRateData] = []
    @State private var weeklyActiveUsersData: [WeeklyActiveUsersData] = []
    @State private var selectedChart: ChartType = .iosVersion
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Use Cases
    private let fetchIOSVersionUseCase = FetchIOSVersionDataUseCase()
    private let fetchSwiftSLOCUseCase = FetchSwiftSLOCDataUseCase()
    private let fetchAdoptionRateUseCase = FetchAdoptionRateDataUseCase()
    private let fetchWeeklyActiveUsersUseCase = FetchWeeklyActiveUsersDataUseCase()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Chart Picker
                VStack(alignment: .leading) {
                    Text("Select Chart")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Picker("Chart Type", selection: $selectedChart) {
                        ForEach(ChartType.allCases, id: \.self) { chartType in
                            Text(chartType.displayName)
                                .tag(chartType)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Selected Chart Display
                if isLoading {
                    ProgressView("Loading data...")
                        .frame(maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack {
                        Text("Error loading data:")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        ScrollView {
                            Text(error)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        Group {
                            switch selectedChart {
                            case .iosVersion:
                                if !iosVersionData.isEmpty {
                                    IOSVersionChart(data: iosVersionData)
                                } else {
                                    EmptyChartView(chartName: "iOS Version Distribution")
                                }
                                
                            case .swiftSLOC:
                                if !swiftSLOCData.isEmpty {
                                    SwiftSLOCChart(data: swiftSLOCData)
                                } else {
                                    EmptyChartView(chartName: "Swift Lines of Code")
                                }
                                
                            case .adoptionRate:
                                if !adoptionRateData.isEmpty {
                                    AdoptionRateChart(data: adoptionRateData)
                                } else {
                                    EmptyChartView(chartName: "Version Adoption Rate")
                                }
                                
                            case .weeklyActiveUsers:
                                if !weeklyActiveUsersData.isEmpty {
                                    WeeklyActiveUsersChart(data: weeklyActiveUsersData)
                                } else {
                                    EmptyChartView(chartName: "Weekly Active Users")
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("iOS Analytics")
            .task {
                await loadAllData()
            }
        }
    }
    
    private func loadAllData() async {
        isLoading = true
        errorMessage = nil
        
        // Execute Use Cases in parallel for better performance
        async let iosVersionTask = executeIOSVersionUseCase()
        async let swiftSLOCTask = executeSwiftSLOCUseCase()
        async let adoptionRateTask = executeAdoptionRateUseCase()
        async let weeklyActiveUsersTask = executeWeeklyActiveUsersUseCase()
        
        // Wait for all results
        let (iosResult, slocResult, adoptionResult, weeklyUsersResult) = await (
            iosVersionTask,
            swiftSLOCTask,
            adoptionRateTask,
            weeklyActiveUsersTask
        )
        
        // Process results
        if let iosData = iosResult {
            iosVersionData = iosData
        }
        
        if let slocData = slocResult {
            swiftSLOCData = slocData
        }
        
        if let adoptionData = adoptionResult {
            adoptionRateData = adoptionData
        }
        
        if let weeklyUsersData = weeklyUsersResult {
            weeklyActiveUsersData = weeklyUsersData
        }
        
        isLoading = false
    }
    
    private func executeIOSVersionUseCase() async -> [IOSVersionData]? {
        do {
            return try await fetchIOSVersionUseCase.execute()
        } catch {
            print("Error in iOS Version use case: \(error)")
            updateErrorMessage("iOS Version: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func executeSwiftSLOCUseCase() async -> [SwiftSLOCData]? {
        do {
            return try await fetchSwiftSLOCUseCase.execute()
        } catch {
            print("Error in Swift SLOC use case: \(error)")
            updateErrorMessage("Swift SLOC: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func executeAdoptionRateUseCase() async -> [AdoptionRateData]? {
        do {
            return try await fetchAdoptionRateUseCase.execute()
        } catch {
            print("Error in Adoption Rate use case: \(error)")
            updateErrorMessage("Adoption Rate: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func executeWeeklyActiveUsersUseCase() async -> [WeeklyActiveUsersData]? {
        do {
            return try await fetchWeeklyActiveUsersUseCase.execute()
        } catch {
            print("Error in Weekly Active Users use case: \(error)")
            updateErrorMessage("Weekly Active Users: \(error.localizedDescription)")
            return nil
        }
    }
    
    @MainActor
    private func updateErrorMessage(_ message: String) {
        if errorMessage == nil {
            errorMessage = message
        } else {
            errorMessage = (errorMessage ?? "") + "\n" + message
        }
    }
}

// MARK: - Empty Chart View Helper
struct EmptyChartView: View {
    let chartName: String
    
    var body: some View {
        VStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Data Available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Unable to load \(chartName) data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}
