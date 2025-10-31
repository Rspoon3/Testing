/// Generates computed properties for each case in an enum to check if the current value matches that case.
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
@attached(member, names: arbitrary)
public macro CaseDetection() = #externalMacro(module: "CaseDetectionPlugin", type: "CaseDetectionMacro")

/// Generates namespaced accessors for enum cases with associated values.
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
/// Use the namespaced syntax to access associated values:
/// ```swift
/// let state = MyState.error(localizedDescription: "Failed")
/// print(state.error?.localizedDescription)  // "Failed"
/// ```
@attached(member, names: arbitrary)
public macro CaseAssociatedValueDetection() = #externalMacro(module: "CaseDetectionPlugin", type: "CaseAssociatedValueDetectionMacro")
