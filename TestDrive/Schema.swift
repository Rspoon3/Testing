import Dependencies
import Foundation
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
                    "genre" TEXT NOT NULL DEFAULT '',
                    "pageCount" INTEGER NOT NULL DEFAULT 0,
                    "isPinned" INTEGER NOT NULL DEFAULT 0,
                    "releaseDate" TEXT NOT NULL DEFAULT ''
                ) STRICT
                """)
                .execute(db)

            try Book.insert {
                Book.Draft(title: "The Mythical Man-Month", author: "Frederick Brooks", genre: "Management", pageCount: 336, isPinned: true, releaseDate: makeDate(1999, 1, 1))
                Book.Draft(title: "Structure and Interpretation of Computer Programs", author: "Harold Abelson & Gerald Sussman", genre: "Computer Science", pageCount: 657, releaseDate: makeDate(1999, 7, 1))
                Book.Draft(title: "The Pragmatic Programmer", author: "David Thomas & Andrew Hunt", genre: "Software", pageCount: 352, releaseDate: makeDate(2008, 10, 20))
                Book.Draft(title: "Clean Code", author: "Robert C. Martin", genre: "Software", pageCount: 464, isPinned: true, releaseDate: makeDate(2008, 8, 1))
                Book.Draft(title: "Designing Data-Intensive Applications", author: "Martin Kleppmann", genre: "Software", pageCount: 616, releaseDate: makeDate(2017, 3, 16))
            }
            .execute(db)
        }
        try migrator.migrate(database)
        defaultDatabase = database
    }
}

nonisolated private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}
