import SwiftUI
import SharingGRDB
import GRDB

struct TableInfo {
    let name: String
    let columns: [ColumnInfo]
    let rowCount: Int
}

struct ColumnInfo {
    let name: String
    let type: String
    let notNull: Bool
    let primaryKey: Bool
}

struct DebugView: View {
    @Dependency(\.defaultDatabase) private var database
    @State private var tables: [TableInfo] = []
    @State private var tableData: [String: [[String: Any]]] = [:]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tables, id: \.name) { table in
                    Section("\(table.name) (\(table.rowCount) records)") {
                        // Schema information
                        DisclosureGroup("Schema") {
                            ForEach(table.columns, id: \.name) { column in
                                SchemaRow(
                                    property: "\(column.name): \(column.type)",
                                    description: buildColumnDescription(column)
                                )
                            }
                        }
                        
                        // Table data
                        if let rows = tableData[table.name] {
                            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                                DisclosureGroup("Record \(index + 1)") {
                                    ForEach(table.columns, id: \.name) { column in
                                        PropertyRow(
                                            label: column.name,
                                            value: formatValue(row[column.name]),
                                            type: column.type
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Database Debug")
            .onAppear {
                loadDatabaseInfo()
            }
            .refreshable {
                loadDatabaseInfo()
            }
        }
    }
    
    private func loadDatabaseInfo() {
        do {
            try database.read { db in
                // Get all table names
                let tableNames = try String.fetchAll(db, sql: """
                    SELECT name FROM sqlite_master 
                    WHERE type='table' AND name NOT LIKE 'sqlite_%'
                """)
                
                var newTables: [TableInfo] = []
                var newTableData: [String: [[String: Any]]] = [:]
                
                for tableName in tableNames {
                    // Get table schema
                    let columnRows = try Row.fetchAll(db, sql: "PRAGMA table_info(\(tableName))")
                    let columns = columnRows.map { row in
                        ColumnInfo(
                            name: row["name"],
                            type: row["type"],
                            notNull: row["notnull"] as Int == 1,
                            primaryKey: row["pk"] as Int == 1
                        )
                    }
                    
                    // Get row count
                    let rowCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(tableName)") ?? 0
                    
                    // Get all data from table
                    let dataRows = try Row.fetchAll(db, sql: "SELECT * FROM \(tableName)")
                    let data = dataRows.map { row in
                        var dict: [String: Any] = [:]
                        for column in columns {
                            dict[column.name] = row[column.name]
                        }
                        return dict
                    }
                    
                    let tableInfo = TableInfo(name: tableName, columns: columns, rowCount: rowCount)
                    newTables.append(tableInfo)
                    newTableData[tableName] = data
                }
                
                DispatchQueue.main.async {
                    self.tables = newTables.sorted { $0.name < $1.name }
                    self.tableData = newTableData
                }
            }
        } catch {
            print("Error loading database info: \(error)")
        }
    }
    
    private func buildColumnDescription(_ column: ColumnInfo) -> String {
        var description = ""
        if column.primaryKey {
            description += "Primary Key"
        }
        if column.notNull {
            description += description.isEmpty ? "Not Null" : ", Not Null"
        }
        return description.isEmpty ? "Optional" : description
    }
    
    private func formatValue(_ value: Any?) -> String {
        guard let value = value else { return "NULL" }
        
        if let date = value as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            return formatter.string(from: date)
        }
        
        return "\(value)"
    }
}

struct PropertyRow: View {
    let label: String
    let value: String
    let type: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(type)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.orange)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
    }
}

struct SchemaRow: View {
    let property: String
    let description: String
    
    var body: some View {
        HStack {
            Text(property)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    DebugView()
}