import Dependencies
import Foundation
import GRDB
import SQLiteData

/// Sets up preview dependencies for SwiftUI previews.
///
/// Call this at the beginning of your preview to configure the database
/// and other dependencies for preview mode.
///
/// Example:
/// ```swift
/// #Preview {
///     setupPreviewDependencies()
///     return MyView()
/// }
/// ```
@discardableResult
public func setupPreviewDependencies() -> Void {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
}
