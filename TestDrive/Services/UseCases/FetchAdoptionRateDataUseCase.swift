import Foundation

// MARK: - Fetch Adoption Rate Data Use Case
class FetchAdoptionRateDataUseCase {
    private let apiService: GrafanaAPIService
    private let endpoint: AdoptionRateEndpoint
    
    init(apiService: GrafanaAPIService = .shared) {
        self.apiService = apiService
        self.endpoint = AdoptionRateEndpoint()
    }
    
    func execute() async throws -> [AdoptionRateData] {
        print("Executing FetchAdoptionRateDataUseCase...")
        
        do {
            let data = try await apiService.executeEndpoint(endpoint)
            print("Successfully fetched adoption rate data: \(data.count) items")
            
            if data.count > 0 {
                print("Sample adoption data: \(data.prefix(3).map { "Version: \($0.version), Rate: \($0.adoptionRate)" })")
            }
            
            return data
        } catch {
            print("Error in FetchAdoptionRateDataUseCase: \(error)")
            throw error
        }
    }
}