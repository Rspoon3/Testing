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
