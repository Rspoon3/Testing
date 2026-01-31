import Foundation

/// Pre-defined templates for common credential types.
///
/// Each template provides a list of secret labels that are commonly used
/// for specific services, making it easier to create credentials.
public enum SecretTemplate: String, CaseIterable, Identifiable, Sendable {
    /// Single secret (default).
    case single

    /// AWS credentials (Access Key ID + Secret Access Key).
    case aws

    /// OAuth credentials (Client ID + Client Secret).
    case oauth

    /// Twitter/X API credentials.
    case twitter

    /// Cloudflare credentials.
    case cloudflare

    /// Stripe payment credentials.
    case stripe

    /// Custom (user-defined labels).
    case custom

    // MARK: - Identifiable

    public var id: String { rawValue }

    // MARK: - Properties

    /// Display name for this template.
    public var displayName: String {
        switch self {
        case .single:
            return "Single Secret"
        case .aws:
            return "AWS"
        case .oauth:
            return "OAuth"
        case .twitter:
            return "Twitter/X"
        case .cloudflare:
            return "Cloudflare"
        case .stripe:
            return "Stripe"
        case .custom:
            return "Custom"
        }
    }

    /// Icon name (SF Symbol) for this template.
    public var iconName: String {
        switch self {
        case .single:
            return "key.fill"
        case .aws:
            return "cloud.fill"
        case .oauth:
            return "lock.shield.fill"
        case .twitter:
            return "bird.fill"
        case .cloudflare:
            return "globe"
        case .stripe:
            return "creditcard.fill"
        case .custom:
            return "pencil.circle.fill"
        }
    }

    /// Pre-defined secret labels for this template.
    ///
    /// Returns an empty array for custom templates, allowing users to define their own labels.
    public var secretLabels: [String] {
        switch self {
        case .single:
            return ["Secret"]
        case .aws:
            return ["Access Key ID", "Secret Access Key"]
        case .oauth:
            return ["Client ID", "Client Secret"]
        case .twitter:
            return [
                "API Key",
                "API Secret",
                "Bearer Token",
                "Access Token",
                "Access Token Secret"
            ]
        case .cloudflare:
            return ["API Key", "S3 Endpoint URL"]
        case .stripe:
            return ["Publishable Key", "Secret Key", "Webhook Secret"]
        case .custom:
            return []
        }
    }

    /// Description of what this template is used for.
    public var description: String {
        switch self {
        case .single:
            return "A single secret value"
        case .aws:
            return "Amazon Web Services credentials"
        case .oauth:
            return "OAuth 2.0 application credentials"
        case .twitter:
            return "Twitter/X API credentials with multiple tokens"
        case .cloudflare:
            return "Cloudflare API and S3-compatible storage credentials"
        case .stripe:
            return "Stripe payment API credentials"
        case .custom:
            return "Define your own secret labels"
        }
    }
}
