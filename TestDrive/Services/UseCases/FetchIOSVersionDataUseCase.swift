import Foundation

// MARK: - Fetch iOS Version Data Use Case
class FetchIOSVersionDataUseCase {
    private let apiService: GrafanaAPIService
    private let endpoint: IOSVersionEndpoint
    
    init(apiService: GrafanaAPIService = .shared) {
        self.apiService = apiService
        self.endpoint = IOSVersionEndpoint()
    }
    
    func execute() async throws -> [IOSVersionData] {
        print("Executing FetchIOSVersionDataUseCase...")
        
        do {
            let data = try await apiService.executeEndpoint(endpoint)
            print("Successfully fetched iOS version data: \(data.count) items")
            return data
        } catch {
            print("Error in FetchIOSVersionDataUseCase: \(error)")
            throw error
        }
    }
}