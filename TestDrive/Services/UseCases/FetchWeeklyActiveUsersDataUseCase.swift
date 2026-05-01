import Foundation

// MARK: - Fetch Weekly Active Users Data Use Case
class FetchWeeklyActiveUsersDataUseCase {
    private let apiService: GrafanaAPIService
    private let endpoint: WeeklyActiveUsersEndpoint
    
    init(apiService: GrafanaAPIService = .shared) {
        self.apiService = apiService
        self.endpoint = WeeklyActiveUsersEndpoint()
    }
    
    func execute() async throws -> [WeeklyActiveUsersData] {
        print("Executing FetchWeeklyActiveUsersDataUseCase...")
        
        do {
            let data = try await apiService.executeEndpoint(endpoint)
            print("Successfully fetched weekly active users data: \(data.count) items")
            
            if data.count > 0 {
                // Show summary of latest week
                if let latestWeek = data.map({ $0.week }).max() {
                    let latestData = data.filter { $0.week == latestWeek }
                    let sortedLatest = latestData.sorted { $0.shareOfUsers > $1.shareOfUsers }
                    print("Latest week summary (top 3): \(sortedLatest.prefix(3).map { "iOS \($0.iosVersion): \(String(format: "%.1f%%", $0.shareAsPercentage))" }.joined(separator: ", "))")
                }
            }
            
            return data
        } catch {
            print("Error in FetchWeeklyActiveUsersDataUseCase: \(error)")
            throw error
        }
    }
}