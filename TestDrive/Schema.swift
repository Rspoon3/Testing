import Dependencies
import SQLiteData

extension DependencyValues {
    mutating func bootstrapDatabase() throws {
        let database = try SQLiteData.defaultDatabase()
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        migrator.registerMigration("createBooks") { db in
            try #sql("""
                CREATE TABLE "books" (
                    "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                    "title" TEXT NOT NULL DEFAULT '',
                    "author" TEXT NOT NULL DEFAULT '',
                    "pageCount" INTEGER NOT NULL DEFAULT 0
                ) STRICT
                """)
                .execute(db)

            try Book.insert {
                Book.Draft(title: "The Pragmatic Programmer", author: "David Thomas & Andrew Hunt", pageCount: 352)
                Book.Draft(title: "Designing Data-Intensive Applications", author: "Martin Kleppmann", pageCount: 616)
                Book.Draft(title: "Clean Code", author: "Robert C. Martin", pageCount: 464)
                Book.Draft(title: "Structure and Interpretation of Computer Programs", author: "Harold Abelson & Gerald Sussman", pageCount: 657)
                Book.Draft(title: "The Mythical Man-Month", author: "Frederick Brooks", pageCount: 336)
            }
            .execute(db)
        }
        try migrator.migrate(database)
        defaultDatabase = database
    }
}
