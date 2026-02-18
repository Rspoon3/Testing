import Foundation
import StructuredQueries

@Table
nonisolated struct Book: Identifiable {
    let id: UUID
    var title: String
    var author: String
    var pageCount: Int
}
