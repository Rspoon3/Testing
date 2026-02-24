import Dependencies
import SQLiteData

extension DependencyValues {
    mutating func bootstrapDatabase() throws {
        let databaseURL = try EnvelopePaths.defaultDatabaseURL()
        let database = try EnvelopeStore.openDatabase(at: databaseURL)
        defaultDatabase = database
    }
}
