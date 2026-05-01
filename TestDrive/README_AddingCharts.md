# Adding New Charts to the Grafana Dashboard

This guide walks you through adding a new chart to the iOS analytics dashboard. The architecture is designed to make this process straightforward and maintainable.

## Overview

The dashboard uses a clean separation of concerns with the following components:

- **Models**: Data structures for each panel
- **Endpoints**: Grafana API query builders and response parsers
- **Use Cases**: Business logic orchestrators
- **Views**: SwiftUI chart components
- **ContentView**: Main coordinator

## Step-by-Step Guide

### 1. Create the Data Model

**File**: `Shared/Models/Panel[X]Model.swift`

Create a model that represents your chart's data structure:

```swift
import Foundation

// Panel X: Your Chart Description
struct YourChartData: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date       // Common for time-series
    let value: Double         // Your main metric
    let category: String?     // Optional grouping field
    
    init(timestamp: Date, value: Double, category: String? = nil) {
        self.timestamp = timestamp
        self.value = value
        self.category = category
    }
    
    enum CodingKeys: String, CodingKey {
        case timestamp, value, category
    }
    
    // Add convenience properties for display
    var displayValue: String {
        return String(format: "%.2f", value)
    }
}
```

**Key Points:**
- Always implement `Identifiable` for SwiftUI charts
- Add `CodingKeys` to exclude `id` from JSON encoding
- Include convenience properties for formatting
- Use clear, descriptive property names

### 2. Create the Endpoint

**File**: `Shared/Services/Endpoints/YourChartEndpoint.swift`

Create an endpoint that knows how to query Grafana and parse the response:

```swift
import Foundation

// MARK: - Your Chart Endpoint (Panel X)
struct YourChartEndpoint: GrafanaEndpoint {
    typealias DataType = YourChartData
    
    // Configure the datasource (Snowflake, InfluxDB, or Postgres)
    let datasource = GrafanaDatasource(
        type: "grafana-snowflake-datasource", 
        uid: "your-datasource-uid"
    )
    let timeRange = GrafanaTimeRange.last30Days
    
    func buildQuery() -> String {
        let sqlQuery = SQLQuery(
            rawSql: """
                SELECT 
                    your_timestamp_field as "time",
                    your_value_field as "value",
                    your_category_field as "category"
                FROM your_table
                WHERE your_conditions
                ORDER BY your_timestamp_field
                """
        )
        
        return GrafanaQueryBuilder.buildQueryPayload(
            datasource: datasource,
            timeRange: timeRange,
            query: sqlQuery
        )
    }
    
    func parseResponse(_ response: GrafanaResponse) throws -> [YourChartData] {
        var allData: [YourChartData] = []
        
        // Standard error checking
        guard !response.results.isEmpty else {
            throw ParsingError.noResultsFound
        }
        
        guard let result = response.results.values.first else {
            throw ParsingError.noResultsFound
        }
        
        guard !result.frames.isEmpty else {
            throw ParsingError.noFramesFound
        }
        
        guard let frame = result.frames.first else {
            throw ParsingError.noFramesFound
        }
        
        guard let values = frame.data?.values else {
            throw ParsingError.insufficientData
        }
        
        // Parse based on your data structure
        // Simple columnar format (most common):
        if values.count >= 2 {
            let count = values[0].count
            for i in 0..<count {
                let timestampValue = try values[0][i].doubleValue() / 1000.0
                let timestamp = Date(timeIntervalSince1970: timestampValue)
                let value = try values[1][i].doubleValue()
                let category = values.count > 2 ? try? values[2][i].stringValue() : nil
                
                let dataPoint = YourChartData(
                    timestamp: timestamp,
                    value: value,
                    category: category
                )
                allData.append(dataPoint)
            }
        }
        
        // For time-series wide format (like Panel 29):
        // Check field labels for series names
        // Parse each series as separate data points
        
        print("Parsed \(allData.count) data points for YourChart")
        return allData
    }
}
```

**Data Format Tips:**
- **Columnar**: Values stored in separate arrays by column
- **Time-series Wide**: Time column + multiple value columns with labels
- **Time-series Long**: Rows with time, series, value columns

### 3. Create the Use Case

**File**: `Shared/Services/UseCases/FetchYourChartDataUseCase.swift`

Create a use case that orchestrates the data fetching:

```swift
import Foundation

// MARK: - Fetch Your Chart Data Use Case
class FetchYourChartDataUseCase {
    private let apiService: GrafanaAPIService
    private let endpoint: YourChartEndpoint
    
    init(apiService: GrafanaAPIService = .shared) {
        self.apiService = apiService
        self.endpoint = YourChartEndpoint()
    }
    
    func execute() async throws -> [YourChartData] {
        print("Executing FetchYourChartDataUseCase...")
        
        do {
            let data = try await apiService.executeEndpoint(endpoint)
            print("Successfully fetched your chart data: \(data.count) items")
            
            // Add any business logic here
            // e.g., filtering, sorting, aggregating
            
            return data
        } catch {
            print("Error in FetchYourChartDataUseCase: \(error)")
            throw error
        }
    }
}
```

### 4. Create the Chart View

**File**: `Shared/Views/YourChart.swift`

Create a SwiftUI view that displays your chart:

```swift
import SwiftUI
import Charts

struct YourChart: View {
    let data: [YourChartData]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Your Chart Title")
                .font(.headline)
                .padding(.bottom, 5)
            
            if data.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(height: 300)
            } else {
                Chart(data) { item in
                    // Choose appropriate mark type:
                    
                    // Line chart for time series
                    LineMark(
                        x: .value("Date", item.timestamp),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(.blue)
                    
                    // Bar chart for categories
                    BarMark(
                        x: .value("Category", item.category ?? "Unknown"),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(.green)
                    
                    // Multi-series line chart
                    LineMark(
                        x: .value("Date", item.timestamp),
                        y: .value("Value", item.value),
                        series: .value("Series", item.category ?? "Default")
                    )
                    .foregroundStyle(by: .value("Series", item.category ?? "Default"))
                }
                .frame(height: 300)
                
                // Add summary or additional info
                if let summary = calculateSummary() {
                    Text(summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func calculateSummary() -> String? {
        guard !data.isEmpty else { return nil }
        let total = data.reduce(0) { $0 + $1.value }
        return "Total: \(String(format: "%.2f", total))"
    }
}
```

**Chart Types:**
- `LineMark`: Time series, trends
- `BarMark`: Categories, comparisons  
- `AreaMark`: Filled areas, cumulative data
- `PointMark`: Scatter plots, individual data points

### 5. Update ContentView and Chart Picker

**File**: `Shared/ContentView.swift`

The dashboard uses a picker to show one chart at a time. Follow these steps to add your new chart:

#### Step 5.1: Add to ChartType Enum

```swift
enum ChartType: String, CaseIterable {
    case iosVersion = "iOS Version Distribution"
    case swiftSLOC = "Swift Lines of Code"
    case adoptionRate = "Version Adoption Rate"
    case weeklyActiveUsers = "Weekly Active Users by iOS Version"
    case yourChart = "Your Chart Name"  // Add this line
    
    var displayName: String {
        return self.rawValue
    }
}
```

#### Step 5.2: Add State and Use Case

```swift
// 1. Add state variable
@State private var yourChartData: [YourChartData] = []

// 2. Add use case
private let fetchYourChartUseCase = FetchYourChartDataUseCase()
```

#### Step 5.3: Add to Parallel Execution

```swift
// 3. Add to parallel execution
async let yourChartTask = executeYourChartUseCase()

let (iosResult, slocResult, adoptionResult, weeklyUsersResult, yourChartResult) = await (
    iosVersionTask,
    swiftSLOCTask,
    adoptionRateTask,
    weeklyActiveUsersTask,
    yourChartTask
)

// 4. Process result
if let yourData = yourChartResult {
    yourChartData = yourData
}
```

#### Step 5.4: Add to Switch Statement

```swift
// 5. Add to the switch statement in the UI
switch selectedChart {
case .iosVersion:
    if !iosVersionData.isEmpty {
        IOSVersionChart(data: iosVersionData)
    } else {
        EmptyChartView(chartName: "iOS Version Distribution")
    }
    
// ... other cases ...

case .yourChart:  // Add this case
    if !yourChartData.isEmpty {
        YourChart(data: yourChartData)
    } else {
        EmptyChartView(chartName: "Your Chart Name")
    }
}
```

#### Step 5.5: Add Execution Function

```swift
// 6. Add execution function
private func executeYourChartUseCase() async -> [YourChartData]? {
    do {
        return try await fetchYourChartUseCase.execute()
    } catch {
        print("Error in Your Chart use case: \(error)")
        updateErrorMessage("Your Chart: \(error.localizedDescription)")
        return nil
    }
}
```

### Chart Picker Benefits

The picker implementation provides several advantages:

- **Performance**: Only loads one chart at a time, reducing memory usage
- **Clean UI**: Focused view without scrolling through multiple charts
- **Easy Navigation**: Segmented picker for quick chart switching
- **Error Isolation**: Errors in one chart don't affect others
- **Extensible**: Adding new charts is just adding enum cases

## Common Patterns

### Datasource Types
- **Snowflake**: `"grafana-snowflake-datasource"`
- **InfluxDB**: `"influxdb"`  
- **PostgreSQL**: `"postgres"`

### Query Types
```swift
// SQL Query (Snowflake/Postgres)
SQLQuery(rawSql: "SELECT ...", format: "time_series") // optional format

// InfluxDB Query
InfluxQuery(query: "from(bucket: ...) |> ...")
```

### Time Ranges
```swift
GrafanaTimeRange.last24Hours
GrafanaTimeRange.last7Days  
GrafanaTimeRange.last30Days
GrafanaTimeRange(from: "now-1y", to: "now")
```

### Error Handling
Always include proper error handling in parsing:
```swift
guard !response.results.isEmpty else {
    throw ParsingError.noResultsFound
}
```

## Testing Your Implementation

1. **Check Console Logs**: Look for parsing debug messages
2. **Verify Data Structure**: Print sample data points
3. **Handle Null Values**: Check for null/missing data
4. **Test Edge Cases**: Empty responses, single data points
5. **Monitor Performance**: Large datasets, slow queries

## Troubleshooting

### Common Issues

**Wrong Data Format**
- Check the `executedQueryString` in response meta
- Verify datasource type and UID
- Check if query needs `format: "time_series"`

**Parsing Errors**  
- Add debug logging to see actual response structure
- Check field labels for series names
- Handle null values appropriately

**Empty Charts**
- Verify data is not filtered out (e.g., zero values)
- Check date ranges and time zone handling
- Ensure data model properties are correct

**Performance Issues**
- Limit data ranges for large datasets
- Consider data aggregation in SQL
- Use background queues for heavy processing

## Best Practices

1. **Keep It Simple**: Start with basic implementation, add complexity later
2. **Follow Patterns**: Use existing endpoints as templates
3. **Add Logging**: Debug parsing issues with console output  
4. **Handle Nulls**: Always check for null/missing values
5. **Test Thoroughly**: Verify with different data scenarios
6. **Document Intent**: Add comments explaining complex parsing logic

## Architecture Benefits

- **Modular**: Each chart is independent
- **Testable**: Use cases can be unit tested
- **Reusable**: Endpoints can be shared between charts
- **Maintainable**: Clear separation of concerns
- **Extensible**: Easy to add new datasources or query types

## Complete Example: Adding a New Chart

Here's a complete walkthrough of adding a hypothetical "Daily Active Users" chart:

### 1. Model (DailyActiveUsersModel.swift)
```swift
struct DailyActiveUsersData: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let activeUsers: Int
    let platform: String
    
    enum CodingKeys: String, CodingKey {
        case date, activeUsers, platform
    }
}
```

### 2. Endpoint (DailyActiveUsersEndpoint.swift)
```swift
struct DailyActiveUsersEndpoint: GrafanaEndpoint {
    typealias DataType = DailyActiveUsersData
    let datasource = GrafanaDatasource(type: "grafana-snowflake-datasource", uid: "3jBPY-jGk")
    let timeRange = GrafanaTimeRange.last7Days
    // ... implementation
}
```

### 3. Use Case (FetchDailyActiveUsersDataUseCase.swift)
```swift
class FetchDailyActiveUsersDataUseCase {
    // ... implementation
}
```

### 4. View (DailyActiveUsersChart.swift)
```swift
struct DailyActiveUsersChart: View {
    let data: [DailyActiveUsersData]
    // ... chart implementation
}
```

### 5. ContentView Updates
```swift
// Add to enum
case dailyActiveUsers = "Daily Active Users"

// Add state
@State private var dailyActiveUsersData: [DailyActiveUsersData] = []

// Add use case
private let fetchDailyActiveUsersUseCase = FetchDailyActiveUsersDataUseCase()

// Add to switch
case .dailyActiveUsers:
    if !dailyActiveUsersData.isEmpty {
        DailyActiveUsersChart(data: dailyActiveUsersData)
    } else {
        EmptyChartView(chartName: "Daily Active Users")
    }
```

That's it! Your new chart will appear in the picker and work seamlessly with the existing architecture.

This architecture makes adding new charts a straightforward process that doesn't require modifying existing code, making the dashboard highly maintainable and extensible.