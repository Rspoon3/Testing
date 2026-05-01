import Foundation
import SharingGRDB
import GRDB

class DatabaseManager {
    static let shared = DatabaseManager()
    private var dbQueue: DatabaseQueue?
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let dbPath = "\(documentsPath)/database.sqlite"
            
            print("Database URL: \(dbPath)")
            
            dbQueue = try DatabaseQueue(path: dbPath)
            
            try dbQueue?.write { db in
                try db.create(table: "books", ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("title", .text).notNull()
                    t.column("author", .text).notNull()
                    t.column("yearPublished", .integer).notNull()
                    t.column("isAvailable", .boolean).notNull().defaults(to: true)
                    t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                }
                
                try db.create(table: "authors", ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("name", .text).notNull()
                    t.column("birthYear", .integer)
                    t.column("nationality", .text).notNull()
                    t.column("isActive", .boolean).notNull().defaults(to: true)
                    t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                }
            }
        } catch {
            print("Database setup error: \(error)")
        }
    }
    
    var database: DatabaseQueue? {
        return dbQueue
    }
}
