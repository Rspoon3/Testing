import Foundation

// MARK: - iOS Version Distribution Endpoint (Panel 42)
struct IOSVersionEndpoint: GrafanaEndpoint {
    typealias DataType = IOSVersionData
    
    let datasource = GrafanaDatasource(type: "grafana-snowflake-datasource", uid: "3jBPY-jGk", format: 0)
    let timeRange = GrafanaTimeRange.last30Days
    
    func buildQuery() -> String {
        let sqlQuery = SQLQuery(rawSql: """
            SELECT 
              CASE 
                WHEN ios_version IN (19, 26) THEN '26'
                ELSE CAST(ios_version AS VARCHAR)
              END AS "iOS Version",
              SUM(cnt_user) AS "Count of Active Users"
            FROM FETCH_SERVICES_PROD.GLITTER_GLUE_REPORTING.IOS_KPI_VERSION
            WHERE week = DATE_TRUNC('WEEK', SYSDATE())
            GROUP BY 1
            ORDER BY 1;
            """)
        
        return GrafanaQueryBuilder.buildQueryPayload(
            datasource: datasource,
            timeRange: timeRange,
            query: sqlQuery
        )
    }
    
    func parseResponse(_ response: GrafanaResponse) throws -> [IOSVersionData] {
        guard !response.results.isEmpty else {
            print("Error: No results in response")
            throw ParsingError.noResultsFound
        }
        
        guard let result = response.results.values.first else {
            print("Error: Could not get first result")
            throw ParsingError.noResultsFound
        }
        
        guard !result.frames.isEmpty else {
            print("Error: No frames in result")
            throw ParsingError.noFramesFound
        }
        
        guard let frame = result.frames.first else {
            print("Error: Could not get first frame")
            throw ParsingError.noFramesFound
        }
        
        guard let values = frame.data?.values else {
            print("Error: No values in frame data")
            throw ParsingError.insufficientData
        }
        
        guard values.count >= 2 else {
            print("Error: Values count is \(values.count), expected at least 2")
            throw ParsingError.insufficientData
        }
        
        let count = values[0].count
        var data: [IOSVersionData] = []
        
        for i in 0..<count {
            let row = [values[0][i], values[1][i]]
            let item = try IOSVersionData(from: row)
            data.append(item)
        }
        
        return data
    }
}