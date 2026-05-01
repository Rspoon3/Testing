import Foundation

// MARK: - Generic Grafana API Service
class GrafanaAPIService {
    private let apiToken = ProcessInfo.processInfo.environment["GRAFANA_API_TOKEN"] ?? ""
    private let baseURL = "https://grafana.fetchrewards.com/api/ds/query"
    
    static let shared = GrafanaAPIService()
    
    private init() {}
    
    // MARK: - Generic Request Method
    func executeEndpoint<T: GrafanaEndpoint>(_ endpoint: T) async throws -> [T.DataType] {
        let queryPayload = endpoint.buildQuery()
        print("Executing endpoint with query: \(queryPayload)")
        
        let data = try await performRequest(with: queryPayload)
        print("Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        let response = try JSONDecoder().decode(GrafanaResponse.self, from: data)
        return try endpoint.parseResponse(response)
    }
    
    // MARK: - Private HTTP Client
    private func performRequest(with body: String) async throws -> Data {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
}