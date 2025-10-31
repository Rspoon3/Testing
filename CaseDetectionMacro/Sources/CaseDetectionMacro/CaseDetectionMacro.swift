/// Generates computed properties for each case in an enum to check if the current value matches that case.
///
/// This macro can **only** be applied to enum types. Applying it to a struct, class, or actor will result in a compile-time error.
///
/// For example, applying `@CaseDetection` to this enum:
/// ```swift
/// @CaseDetection
/// enum MyState {
///     case connecting
///     case messaging(message: String)
///     case sent
/// }
/// ```
///
/// Will generate these properties:
/// ```swift
/// var isConnecting: Bool { ... }
/// var isMessaging: Bool { ... }
/// var isSent: Bool { ... }
/// ```
///
/// ## Usage
/// Use the generated properties to check the current case:
/// ```swift
/// let state = MyState.connecting
/// if state.isConnecting {
///     print("Currently connecting")
/// }
/// ```
///
/// ## Requirements
/// - The macro must be applied to an `enum` type
/// - Applying to non-enum types (struct, class, actor) will fail to compile
///
/// ## Generated Code
/// For each enum case, a computed property named `is{CaseName}` is generated that returns `true` if the enum matches that case, `false` otherwise.
@attached(member, names: arbitrary)
public macro CaseDetection() = #externalMacro(module: "CaseDetectionPlugin", type: "CaseDetectionMacro")

/// Generates namespaced accessors for enum cases with associated values.
///
/// This macro can **only** be applied to enum types. Applying it to a struct, class, or actor will result in a compile-time error.
///
/// For example, applying `@CaseAssociatedValueDetection` to this enum:
/// ```swift
/// @CaseAssociatedValueDetection
/// enum MyState {
///     case connecting
///     case error(localizedDescription: String)
///     case sent(date: Date, count: Int)
/// }
/// ```
///
/// Will generate nested structs and properties:
/// ```swift
/// struct ErrorAssociatedValues {
///     let localizedDescription: String
/// }
///
/// var error: ErrorAssociatedValues? {
///     if case .error(let localizedDescription) = self {
///         return ErrorAssociatedValues(localizedDescription: localizedDescription)
///     }
///     return nil
/// }
///
/// struct SentAssociatedValues {
///     let date: Date
///     let count: Int
/// }
///
/// var sent: SentAssociatedValues? { ... }
/// ```
///
/// ## Usage
/// Use the namespaced syntax to access associated values:
/// ```swift
/// let state = MyState.error(localizedDescription: "Failed")
/// print(state.error?.localizedDescription)  // "Failed"
///
/// // Works great with optional chaining
/// if let sentInfo = state.sent {
///     print("Sent at \(sentInfo.date) with count \(sentInfo.count)")
/// }
/// ```
///
/// ## Requirements
/// - The macro must be applied to an `enum` type
/// - Applying to non-enum types (struct, class, actor) will fail to compile
/// - Only enum cases with associated values generate accessors
///
/// ## Generated Code
/// For each enum case with associated values:
/// - A nested struct named `{CaseName}AssociatedValues` containing the associated value properties
/// - A computed property named `{caseName}` that returns an optional struct with the values if the enum matches that case
@attached(member, names: arbitrary)
public macro CaseAssociatedValueDetection() = #externalMacro(module: "CaseDetectionPlugin", type: "CaseAssociatedValueDetectionMacro")
