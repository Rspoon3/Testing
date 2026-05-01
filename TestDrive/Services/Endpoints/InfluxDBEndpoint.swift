import Foundation

// MARK: - Swift SLOC Endpoint (Panel 71)
struct SwiftSLOCEndpoint: GrafanaEndpoint {
    typealias DataType = SwiftSLOCData
    
    let datasource = GrafanaDatasource(type: "influxdb", uid: "yp_G5GaVz")
    let timeRange = GrafanaTimeRange.last30Days
    
    func buildQuery() -> String {
        let influxQuery = InfluxQuery(query: """
            from(bucket: "ios_analytics")
              |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
              |> filter(fn: (r) => r["_measurement"] == "all")
              |> filter(fn: (r) => r["_field"] == "code")
              |> aggregateWindow(every: v.windowPeriod, fn: last, createEmpty: false)
              |> map(fn: (r) => ({ _time: r._time, _value: r._value, _field: "Swift SLOC" }))
            """)
        
        return GrafanaQueryBuilder.buildQueryPayload(
            datasource: datasource,
            timeRange: timeRange,
            query: influxQuery
        )
    }
    
    func parseResponse(_ response: GrafanaResponse) throws -> [SwiftSLOCData] {
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
        
        // For InfluxDB data, we have:
        // values[0] = array of timestamps
        // values[1] = array of SLOC values
        // The field name is in the schema
        let fieldName = frame.schema?.fields.last?.name ?? "Swift SLOC"
        
        let count = values[0].count
        var data: [SwiftSLOCData] = []
        
        for i in 0..<count {
            // Create a synthetic row with timestamp, value, and field name
            let row = [values[0][i], values[1][i], AnyCodableValue.string(fieldName)]
            let item = try SwiftSLOCData(from: row)
            data.append(item)
        }
        
        return data
    }
}