import Foundation
import StructuredQueries

@Table
nonisolated struct Book: Identifiable {
    let id: UUID
    var authorID: Author.ID
    var title: String
    var genre: String
    var pageCount: Int
    var isPinned = false
    var releaseDate: Date
}

extension Book {
    /// The release year derived from `releaseDate` for Swift-side sectioning.
    var releaseYear: Int {
        Calendar.current.component(.year, from: releaseDate)
    }
}

extension Book.TableColumns {
    /// The release year extracted from `releaseDate` at the SQL level
    /// for use in `.order`, `.where`, and `.select`.
    var releaseYear: some QueryExpression<Int> {
        #sql("CAST(strftime('%Y', \(releaseDate)) AS INTEGER)", as: Int.self)
    }
}
