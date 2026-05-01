import Foundation

// MARK: - Adoption Rate Endpoint (Panel 6)
struct AdoptionRateEndpoint: GrafanaEndpoint {
    typealias DataType = AdoptionRateData
    
    let datasource = GrafanaDatasource(type: "postgres", uid: "XL6hluHnz")
    let timeRange = GrafanaTimeRange.last7Days
    
    func buildQuery() -> String {
        let sqlQuery = SQLQuery(
            rawSql: """
                SELECT timestamp_utc as "time", version, adoption_rate as v
                FROM (
                  SELECT *, dense_rank() over (partition by timestamp_utc order by adoption_rate desc) as rank
                  FROM mobile_stability_history
                  WHERE crash_state = 'crash-free'
                    AND platform = 'IOS'
                    AND version not like '%automation%'
                    AND version not like '%gabelilly%'
                    AND version not like '%qa-build%'
                    AND version != 'all'
                    AND timestamp_utc > $__unixEpochTo() - 5400 --Latest time -90 minutes
                  ORDER BY timestamp_utc desc, rank asc
                ) top5
                WHERE top5.rank < 8
                ORDER BY timestamp_utc
                """,
            format: "time_series"
        )
        
        return GrafanaQueryBuilder.buildQueryPayload(
            datasource: datasource,
            timeRange: timeRange,
            query: sqlQuery
        )
    }
    
    func parseResponse(_ response: GrafanaResponse) throws -> [AdoptionRateData] {
        var allData: [AdoptionRateData] = []
        
        print("Parsing adoption rate data...")
        print("Number of results: \(response.results.count)")
        
        for (key, result) in response.results {
            print("Processing result key: \(key)")
            print("Number of frames: \(result.frames.count)")
            
            for (frameIndex, frame) in result.frames.enumerated() {
                print("Frame \(frameIndex):")
                
                // Check the schema for field names
                if let fields = frame.schema?.fields {
                    print("  Fields: \(fields.map { $0.name })")
                }
                
                guard let values = frame.data?.values else {
                    print("  No values in frame")
                    continue
                }
                
                print("  Number of value arrays: \(values.count)")
                if !values.isEmpty {
                    print("  First array count: \(values[0].count)")
                }
                
                // For Postgres time series data, the structure might be:
                // values[0] = timestamps
                // values[1..n] = values for each version
                // The version names are in the field labels
                
                if let fields = frame.schema?.fields, fields.count > 1 {
                    // Each field after the first represents a version
                    for fieldIndex in 1..<fields.count {
                        let field = fields[fieldIndex]
                        // Version is in the labels, not the field name
                        let version = field.labels?["version"] ?? field.name
                        
                        if fieldIndex < values.count {
                            let timestamps = values[0]
                            let versionValues = values[fieldIndex]
                            
                            for i in 0..<min(timestamps.count, versionValues.count) {
                                let row = [timestamps[i], AnyCodableValue.string(version), versionValues[i]]
                                do {
                                    let item = try AdoptionRateData(from: row)
                                    allData.append(item)
                                } catch {
                                    print("  Error parsing row \(i) for version \(version): \(error)")
                                }
                            }
                        }
                    }
                } else if values.count >= 3 {
                    // Fallback to original parsing if structure is different
                    let count = values[0].count
                    for i in 0..<count {
                        let row = [values[0][i], values[1][i], values[2][i]]
                        do {
                            let item = try AdoptionRateData(from: row)
                            allData.append(item)
                        } catch {
                            print("  Error parsing row \(i): \(error)")
                        }
                    }
                }
            }
        }
        
        print("Total adoption rate items parsed: \(allData.count)")
        if !allData.isEmpty {
            let versions = Set(allData.map { $0.version })
            print("Unique versions found: \(versions)")
        }
        
        return allData
    }
}