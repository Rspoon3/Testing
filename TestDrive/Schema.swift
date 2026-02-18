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
        migrator.registerMigration("createBooksAndAuthors") { db in
            try #sql("""
                CREATE TABLE "authors" (
                    "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                    "name" TEXT NOT NULL DEFAULT ''
                ) STRICT
                """)
                .execute(db)

            try #sql("""
                CREATE TABLE "books" (
                    "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                    "authorID" TEXT NOT NULL REFERENCES "authors"("id"),
                    "title" TEXT NOT NULL DEFAULT '',
                    "genre" TEXT NOT NULL DEFAULT '',
                    "pageCount" INTEGER NOT NULL DEFAULT 0,
                    "isPinned" INTEGER NOT NULL DEFAULT 0,
                    "releaseDate" TEXT NOT NULL DEFAULT ''
                ) STRICT
                """)
                .execute(db)

            let brooks = UUID()
            let abelson = UUID()
            let thomas = UUID()
            let martin = UUID()
            let kleppmann = UUID()
            let kim = UUID()

            try Author.insert {
                Author.Draft(id: brooks, name: "Frederick Brooks")
                Author.Draft(id: abelson, name: "Harold Abelson")
                Author.Draft(id: thomas, name: "David Thomas")
                Author.Draft(id: martin, name: "Robert C. Martin")
                Author.Draft(id: kleppmann, name: "Martin Kleppmann")
                Author.Draft(id: kim, name: "Gene Kim")
            }
            .execute(db)

            try Book.insert {
                Book.Draft(authorID: brooks, title: "The Mythical Man-Month", genre: "Management", pageCount: 336, isPinned: true, releaseDate: makeDate(1999, 1, 1))
                Book.Draft(authorID: abelson, title: "Structure and Interpretation of Computer Programs", genre: "Computer Science", pageCount: 657, releaseDate: makeDate(1999, 7, 1))
                Book.Draft(authorID: thomas, title: "The Pragmatic Programmer", genre: "Software", pageCount: 352, releaseDate: makeDate(2008, 10, 20))
                Book.Draft(authorID: martin, title: "Clean Code", genre: "Software", pageCount: 464, isPinned: true, releaseDate: makeDate(2008, 8, 1))
                Book.Draft(authorID: martin, title: "The Clean Coder", genre: "Software", pageCount: 256, releaseDate: makeDate(2011, 5, 13))
                Book.Draft(authorID: kleppmann, title: "Designing Data-Intensive Applications", genre: "Software", pageCount: 616, releaseDate: makeDate(2017, 3, 16))
                Book.Draft(authorID: kim, title: "The Phoenix Project", genre: "Management", pageCount: 432, releaseDate: makeDate(2013, 1, 10))
                Book.Draft(authorID: kim, title: "The Unicorn Project", genre: "Management", pageCount: 352, releaseDate: makeDate(2019, 11, 26))
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
