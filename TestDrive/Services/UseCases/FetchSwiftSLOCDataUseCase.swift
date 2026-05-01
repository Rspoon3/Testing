import Foundation

// MARK: - Fetch Swift SLOC Data Use Case
class FetchSwiftSLOCDataUseCase {
    private let apiService: GrafanaAPIService
    private let endpoint: SwiftSLOCEndpoint
    
    init(apiService: GrafanaAPIService = .shared) {
        self.apiService = apiService
        self.endpoint = SwiftSLOCEndpoint()
    }
    
    func execute() async throws -> [SwiftSLOCData] {
        print("Executing FetchSwiftSLOCDataUseCase...")
        
        do {
            let data = try await apiService.executeEndpoint(endpoint)
            print("Successfully fetched Swift SLOC data: \(data.count) items")
            return data
        } catch {
            print("Error in FetchSwiftSLOCDataUseCase: \(error)")
            throw error
        }
    }
}