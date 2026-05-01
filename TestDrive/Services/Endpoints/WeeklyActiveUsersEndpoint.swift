import Foundation

// MARK: - Weekly Active Users Distribution Endpoint (Panel 29)
struct WeeklyActiveUsersEndpoint: GrafanaEndpoint {
    typealias DataType = WeeklyActiveUsersData
    
    let datasource = GrafanaDatasource(type: "grafana-snowflake-datasource", uid: "3jBPY-jGk")
    let timeRange = GrafanaTimeRange.last30Days
    
    func buildQuery() -> String {
        let sqlQuery = SQLQuery(
            rawSql: """
                SELECT 
                    week,
                    CASE 
                        WHEN ios_version IN ('19', '26') THEN '26'
                        ELSE ios_version
                    END AS ios_version_grouped,
                    SUM(share_user) AS "iOS"
                FROM 
                    FETCH_SERVICES_PROD.GLITTER_GLUE_REPORTING.IOS_KPI_VERSION
                GROUP BY 
                    week, ios_version_grouped
                ORDER BY 
                    week, ios_version_grouped
                """
        )
        
        let query = GrafanaQueryBuilder.buildQueryPayload(
            datasource: datasource,
            timeRange: timeRange,
            query: sqlQuery
        )
        
        print("WeeklyActiveUsersEndpoint building query: \(query)")
        return query
    }
    
    func parseResponse(_ response: GrafanaResponse) throws -> [WeeklyActiveUsersData] {
        var allData: [WeeklyActiveUsersData] = []
        
        print("Parsing weekly active users data...")
        print("Number of results: \(response.results.count)")
        
        for (key, result) in response.results {
            print("Processing result key: \(key)")
            print("Number of frames: \(result.frames.count)")
            
            for (frameIndex, frame) in result.frames.enumerated() {
                print("Frame \(frameIndex):")
                
                // Check the schema for field names
                if let fields = frame.schema?.fields {
                    print("  Fields: \(fields.map { "\($0.name) - \($0.labels ?? [:])" })")
                }
                
                guard let values = frame.data?.values else {
                    print("  No values in frame")
                    continue
                }
                
                print("  Number of value arrays: \(values.count)")
                if !values.isEmpty {
                    print("  First array count: \(values[0].count)")
                }
                
                // For this endpoint, the structure is:
                // values[0] = week timestamps
                // values[1..n] = share values for each iOS version
                // The iOS version names are in the field labels
                
                if let fields = frame.schema?.fields, fields.count > 1 {
                    let timestamps = values[0]
                    
                    // Process each iOS version field (skip the first field which is the timestamp)
                    for fieldIndex in 1..<fields.count {
                        let field = fields[fieldIndex]
                        // iOS version is in the labels under "IOS_VERSION_GROUPED"
                        let iosVersion = field.labels?["IOS_VERSION_GROUPED"] ?? "Unknown"
                        
                        print("  Processing iOS version: \(iosVersion)")
                        
                        if fieldIndex < values.count {
                            let versionValues = values[fieldIndex]
                            
                            for i in 0..<min(timestamps.count, versionValues.count) {
                                do {
                                    let timestampValue = try timestamps[i].doubleValue() / 1000.0
                                    let week = Date(timeIntervalSince1970: timestampValue)
                                    
                                    // Skip null values
                                    if case .null = versionValues[i] {
                                        continue
                                    }
                                    
                                    let shareValue = try versionValues[i].doubleValue()
                                    
                                    // Only include non-zero values to reduce noise
                                    if shareValue > 0.0 {
                                        let dataPoint = WeeklyActiveUsersData(
                                            week: week,
                                            iosVersion: iosVersion,
                                            shareOfUsers: shareValue
                                        )
                                        allData.append(dataPoint)
                                    }
                                } catch {
                                    print("  Error parsing row \(i) for iOS version \(iosVersion): \(error)")
                                }
                            }
                        }
                    }
                }
            }
        }
        
        print("Total weekly active users data points parsed: \(allData.count)")
        if !allData.isEmpty {
            let versions = Set(allData.map { $0.iosVersion })
            print("Unique iOS versions found: \(versions.sorted())")
            
            // Show latest week's data summary
            if let latestWeek = allData.map({ $0.week }).max() {
                let latestData = allData.filter { $0.week == latestWeek }
                print("Latest week (\(latestWeek)) data:")
                for item in latestData.sorted(by: { $0.shareOfUsers > $1.shareOfUsers }) {
                    print("  iOS \(item.iosVersion): \(String(format: "%.2f%%", item.shareAsPercentage))")
                }
            }
        }
        
        return allData
    }
}