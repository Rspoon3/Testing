import Foundation

/// Represents the status of a vault share invitation.
///
/// Tracks whether a participant has accepted, declined, or is still pending
/// response to a vault share invitation.
public enum AcceptanceStatus: String, Codable, Sendable {
    /// Share invitation is pending acceptance.
    case pending

    /// Share invitation has been accepted.
    case accepted

    /// Share invitation has been declined.
    case declined
}
