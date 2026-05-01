import Foundation

// MARK: - Grafana Endpoint Protocol
protocol GrafanaEndpoint {
    associatedtype DataType: Codable
    
    /// The datasource configuration for this endpoint
    var datasource: GrafanaDatasource { get }
    
    /// The time range for the query
    var timeRange: GrafanaTimeRange { get }
    
    /// Build the query payload for this endpoint
    func buildQuery() -> String
    
    /// Parse the Grafana response into the expected data type
    func parseResponse(_ response: GrafanaResponse) throws -> [DataType]
}

// MARK: - Supporting Types
struct GrafanaDatasource: Codable {
    let type: String
    let uid: String
    let format: Int?
    
    init(type: String, uid: String, format: Int? = nil) {
        self.type = type
        self.uid = uid
        self.format = format
    }
}

struct GrafanaTimeRange: Codable {
    let from: String
    let to: String
    
    static let last30Days = GrafanaTimeRange(from: "now-30d", to: "now")
    static let last7Days = GrafanaTimeRange(from: "now-7d", to: "now")
    static let last24Hours = GrafanaTimeRange(from: "now-24h", to: "now")
}

// MARK: - Query Builder Helper
struct GrafanaQueryBuilder {
    static func buildQueryPayload(
        refId: String = "A",
        datasource: GrafanaDatasource,
        timeRange: GrafanaTimeRange,
        query: GrafanaQuery
    ) -> String {
        var datasourceDict: [String: Any] = [
            "type": datasource.type,
            "uid": datasource.uid
        ]
        
        if let format = datasource.format {
            datasourceDict["format"] = format
        }
        
        var queryDict: [String: Any] = [
            "refId": refId,
            "datasource": datasourceDict
        ]
        
        // Merge query dictionary
        query.toDictionary().forEach { key, value in
            queryDict[key] = value
        }
        
        let payload: [String: Any] = [
            "queries": [queryDict],
            "from": timeRange.from,
            "to": timeRange.to
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        
        return jsonString
    }
}

// MARK: - Query Types
protocol GrafanaQuery {
    func toDictionary() -> [String: Any]
}

struct SQLQuery: GrafanaQuery {
    let rawSql: String
    let format: String?
    
    init(rawSql: String, format: String? = nil) {
        self.rawSql = rawSql
        self.format = format
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["rawSql": rawSql]
        if let format = format {
            dict["format"] = format
        }
        return dict
    }
}

struct InfluxQuery: GrafanaQuery {
    let query: String
    
    init(query: String) {
        self.query = query
    }
    
    func toDictionary() -> [String: Any] {
        return ["query": query]
    }
}