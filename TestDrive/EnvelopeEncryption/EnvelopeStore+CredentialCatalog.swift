import Foundation
import SQLiteData
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension EnvelopeStore {
    struct CredentialSummary: Identifiable, Hashable {
        let id: Credential.ID
        let label: String
        let type: VaultItemType
    }

    struct CredentialSecretDisplay: Identifiable, Hashable {
        let id: Secret.ID
        let label: String
        let value: String
    }

    struct CredentialAttributeDisplay: Identifiable, Hashable {
        let id: CredentialAttribute.ID
        let kind: CredentialAttributeKind
        let name: String
        let value: String
    }

    struct CredentialFileDisplay: Identifiable, Hashable {
        let id: CredentialSecretFile.ID
        let label: String
        let fileName: String
        let mimeType: String?
        let decryptedData: Data
        let decryptedByteCount: Int
    }

    struct CredentialDetail: Identifiable, Hashable {
        let id: Credential.ID
        let label: String
        let type: VaultItemType
        let secretFields: [CredentialSecretDisplay]
        let attributes: [CredentialAttributeDisplay]
        let files: [CredentialFileDisplay]
    }

    /// Ensures one real database-backed example exists for each item type.
    func ensureDemoCredentialCatalog(vaultName: String = "Catalog Examples") throws -> [CredentialSummary] {
        let vaultID = try loadOrCreateVault(named: vaultName)
        for blueprint in Self.demoBlueprints {
            _ = try ensureCredential(vaultID: vaultID, blueprint: blueprint)
        }
        return try loadCredentialSummaries(vaultID: vaultID)
    }

    /// Loads credential list rows for one vault.
    func loadCredentialSummaries(vaultID: Vault.ID) throws -> [CredentialSummary] {
        let credentials = try database.read { db in
            try VaultItem
                .where { $0.vaultID.eq(vaultID) }
                .fetchAll(db)
        }

        return credentials
            .map {
                CredentialSummary(
                    id: $0.id,
                    label: $0.title,
                    type: $0.type
                )
            }
            .sorted { lhs, rhs in
                lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
    }

    /// Loads one credential's full display model (decrypting secret fields and files).
    func loadCredentialDetail(credentialID: Credential.ID) throws -> CredentialDetail {
        guard let credential = try database.read({ db in
            try VaultItem.where { $0.id.eq(credentialID) }.fetchOne(db)
        }) else {
            throw StoreError.itemNotFound
        }

        let type = credential.type

        let secretRows = try database.read { db in
            try GenericItemSecretField
                .where { $0.itemID.eq(credentialID) }
                .fetchAll(db)
        }
        let attributeRows = try database.read { db in
            try CredentialAttribute
                .where { $0.credentialID.eq(credentialID) }
                .fetchAll(db)
        }
        let fileRows = try database.read { db in
            try CredentialSecretFile
                .where { $0.credentialID.eq(credentialID) }
                .fetchAll(db)
        }

        var secretFields: [CredentialSecretDisplay] = []
        for row in secretRows.sorted(by: { $0.fieldName < $1.fieldName }) {
            let plaintext = try revealSecret(secretID: row.id)
            let value = String(data: plaintext, encoding: .utf8) ?? "<\(plaintext.count) bytes binary>"
            secretFields.append(
                CredentialSecretDisplay(
                    id: row.id,
                    label: row.fieldName,
                    value: value
                )
            )
        }

        let attributes = attributeRows
            .map {
                CredentialAttributeDisplay(
                    id: $0.id,
                    kind: CredentialAttributeKind(rawValue: $0.kindRawValue) ?? .custom,
                    name: $0.name,
                    value: $0.value
                )
            }
            .sorted { lhs, rhs in
                if lhs.kind.rawValue == rhs.kind.rawValue {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.kind.rawValue.localizedCaseInsensitiveCompare(rhs.kind.rawValue) == .orderedAscending
            }

        var files: [CredentialFileDisplay] = []
        for row in fileRows.sorted(by: { $0.fileName < $1.fileName }) {
            let plaintext = try revealSecretFile(fileID: row.id)
            files.append(
                CredentialFileDisplay(
                    id: row.id,
                    label: row.label,
                    fileName: row.fileName,
                    mimeType: row.mimeType,
                    decryptedData: plaintext,
                    decryptedByteCount: plaintext.count
                )
            )
        }

        return CredentialDetail(
            id: credential.id,
            label: credential.title,
            type: type,
            secretFields: secretFields,
            attributes: attributes,
            files: files
        )
    }
}

private extension EnvelopeStore {
    struct DemoSecret {
        let label: String
        let value: String
    }

    struct DemoAttribute {
        let kind: CredentialAttributeKind
        let name: String?
        let value: String
    }

    struct DemoFile {
        let label: String
        let fileName: String
        let mimeType: String?
        let plaintext: () -> Data
    }

    struct DemoBlueprint {
        let label: String
        let type: VaultItemType
        let initialSecret: DemoSecret
        let additionalSecrets: [DemoSecret]
        let attributes: [DemoAttribute]
        let files: [DemoFile]
    }

    static let demoBlueprints: [DemoBlueprint] = [
        DemoBlueprint(
            label: "Stripe Prod",
            type: .genericSecret,
            initialSecret: DemoSecret(label: "apiKey", value: "sk_live_demo"),
            additionalSecrets: [
                DemoSecret(label: "webhookSecret", value: "whsec_demo")
            ],
            attributes: [
                DemoAttribute(kind: .environment, name: nil, value: "production"),
                DemoAttribute(kind: .link, name: nil, value: "https://dashboard.stripe.com"),
                DemoAttribute(kind: .associatedEmail, name: nil, value: "payments@example.com")
            ],
            files: []
        ),
        DemoBlueprint(
            label: "Xcode Cloud Team Plan",
            type: .softwareLicense,
            initialSecret: DemoSecret(label: "licenseKey", value: "LICENSE-APPLE-DEMO-1234"),
            additionalSecrets: [],
            attributes: [
                DemoAttribute(kind: .associatedEmail, name: nil, value: "ios@example.com")
            ],
            files: []
        ),
        DemoBlueprint(
            label: "GitHub Login",
            type: .usernamePassword,
            initialSecret: DemoSecret(label: "username", value: "dev@example.com"),
            additionalSecrets: [
                DemoSecret(label: "password", value: "super-secret-password")
            ],
            attributes: [
                DemoAttribute(kind: .link, name: nil, value: "https://github.com/login")
            ],
            files: []
        ),
        DemoBlueprint(
            label: "GitHub PAT",
            type: .personalAccessToken,
            initialSecret: DemoSecret(label: "token", value: "ghp_demo_personal_access_token"),
            additionalSecrets: [],
            attributes: [
                DemoAttribute(kind: .note, name: nil, value: "Scopes: repo, workflow")
            ],
            files: []
        ),
        DemoBlueprint(
            label: "Prod Postgres",
            type: .databaseCredential,
            initialSecret: DemoSecret(label: "password", value: "postgres-password-demo"),
            additionalSecrets: [
                DemoSecret(label: "username", value: "app_user")
            ],
            attributes: [
                DemoAttribute(kind: .environment, name: nil, value: "production"),
                DemoAttribute(kind: .link, name: nil, value: "postgres://db.example.com:5432/app_prod")
            ],
            files: []
        ),
        DemoBlueprint(
            label: "iOS App Store Signing",
            type: .mobileReleaseSigning,
            initialSecret: DemoSecret(label: "issuerID", value: "00000000-0000-0000-0000-000000000000"),
            additionalSecrets: [
                DemoSecret(label: "keyID", value: "ABC123DEFG")
            ],
            attributes: [
                DemoAttribute(kind: .note, name: nil, value: "Team ID: ABCDE12345, App ID: com.example.app"),
                DemoAttribute(kind: .associatedEmail, name: nil, value: "release@example.com")
            ],
            files: [
                DemoFile(
                    label: "App Store Connect API Key",
                    fileName: "AuthKey_ABC123DEFG.p8",
                    mimeType: "application/x-pkcs8",
                    plaintext: { Data("-----BEGIN PRIVATE KEY-----demo-----END PRIVATE KEY-----".utf8) }
                )
            ]
        ),
        DemoBlueprint(
            label: "Visa Platinum",
            type: .creditCard,
            initialSecret: DemoSecret(label: "cardNumber", value: "4111 1111 1111 1234"),
            additionalSecrets: [
                DemoSecret(label: "cvv", value: "789")
            ],
            attributes: [
                DemoAttribute(kind: .issuer, name: nil, value: "Chase"),
                DemoAttribute(kind: .network, name: nil, value: "Visa"),
                DemoAttribute(kind: .custom, name: "cardholder", value: "Jane Doe"),
                DemoAttribute(kind: .expirationDate, name: nil, value: "09/2028"),
                DemoAttribute(kind: .address, name: "billing address", value: "123 Main St, Anytown, CA 90210")
            ],
            files: []
        ),
        DemoBlueprint(
            label: "California Driver's License",
            type: .driversLicense,
            initialSecret: DemoSecret(label: "licenseNumber", value: "D1234567"),
            additionalSecrets: [],
            attributes: [
                DemoAttribute(kind: .custom, name: "full name", value: "Jane Doe"),
                DemoAttribute(kind: .dateOfBirth, name: nil, value: "1990-03-15"),
                DemoAttribute(kind: .expirationDate, name: nil, value: "2029-03-15"),
                DemoAttribute(kind: .custom, name: "state", value: "California"),
                DemoAttribute(kind: .custom, name: "class", value: "C"),
                DemoAttribute(kind: .address, name: nil, value: "123 Main St, Anytown, CA 90210")
            ],
            files: [
                DemoFile(
                    label: "License Photo",
                    fileName: "license.jpeg",
                    mimeType: "image/jpeg",
                    plaintext: {
                        EnvelopeStore.imageAssetData(named: "license")
                            ?? Data("missing-license-image-asset".utf8)
                    }
                )
            ]
        ),
        DemoBlueprint(
            label: "US Passport",
            type: .passport,
            initialSecret: DemoSecret(label: "passportNumber", value: "X12345678"),
            additionalSecrets: [],
            attributes: [
                DemoAttribute(kind: .custom, name: "full name", value: "Jane Doe"),
                DemoAttribute(kind: .dateOfBirth, name: nil, value: "1990-03-15"),
                DemoAttribute(kind: .expirationDate, name: nil, value: "2033-06-01"),
                DemoAttribute(kind: .custom, name: "nationality", value: "United States"),
                DemoAttribute(kind: .custom, name: "issuing country", value: "United States"),
                DemoAttribute(kind: .custom, name: "place of birth", value: "Los Angeles, CA")
            ],
            files: []
        ),
        DemoBlueprint(
            label: "Social Security",
            type: .socialSecurityNumber,
            initialSecret: DemoSecret(label: "ssn", value: "123-45-6789"),
            additionalSecrets: [],
            attributes: [
                DemoAttribute(kind: .custom, name: "full name", value: "Jane Doe"),
                DemoAttribute(kind: .dateOfBirth, name: nil, value: "1990-03-15"),
                DemoAttribute(kind: .note, name: nil, value: "Keep physical card in a secure location")
            ],
            files: []
        ),
        DemoBlueprint(
            label: "Home Wi-Fi Router",
            type: .router,
            initialSecret: DemoSecret(label: "wifiPassword", value: "MyS3cur3W1f1!"),
            additionalSecrets: [
                DemoSecret(label: "adminPassword", value: "admin-p@ssw0rd")
            ],
            attributes: [
                DemoAttribute(kind: .custom, name: "SSID", value: "HomeNetwork_5G"),
                DemoAttribute(kind: .custom, name: "admin URL", value: "192.168.1.1"),
                DemoAttribute(kind: .custom, name: "admin username", value: "admin"),
                DemoAttribute(kind: .custom, name: "IP address", value: "192.168.1.1"),
                DemoAttribute(kind: .network, name: nil, value: "WPA3"),
                DemoAttribute(kind: .custom, name: "model", value: "ASUS RT-AX88U")
            ],
            files: []
        ),
        DemoBlueprint(
            label: "Chase Checking",
            type: .bankAccount,
            initialSecret: DemoSecret(label: "accountNumber", value: "000123456789"),
            additionalSecrets: [
                DemoSecret(label: "routingNumber", value: "021000021"),
                DemoSecret(label: "onlineBankingPassword", value: "b@nk-s3cure!")
            ],
            attributes: [
                DemoAttribute(kind: .issuer, name: "bank", value: "JPMorgan Chase"),
                DemoAttribute(kind: .custom, name: "account holder", value: "Jane Doe"),
                DemoAttribute(kind: .custom, name: "account type", value: "Checking"),
                DemoAttribute(kind: .link, name: nil, value: "https://chase.com"),
                DemoAttribute(kind: .custom, name: "online username", value: "janedoe_chase")
            ],
            files: []
        ),
        DemoBlueprint(
            label: "Ethereum Wallet",
            type: .cryptoWallet,
            initialSecret: DemoSecret(label: "seedPhrase", value: "abandon ability able about above absent absorb abstract absurd abuse access accident"),
            additionalSecrets: [
                DemoSecret(label: "privateKey", value: "0xdeadbeef1234567890abcdef1234567890abcdef1234567890abcdef12345678")
            ],
            attributes: [
                DemoAttribute(kind: .custom, name: "wallet name", value: "Primary ETH Wallet"),
                DemoAttribute(kind: .custom, name: "public address", value: "0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18"),
                DemoAttribute(kind: .network, name: nil, value: "Ethereum Mainnet"),
                DemoAttribute(kind: .custom, name: "wallet app", value: "MetaMask"),
                DemoAttribute(kind: .note, name: nil, value: "Hardware wallet backup stored in safe deposit box")
            ],
            files: []
        ),
        DemoBlueprint(
            label: "Costco Membership",
            type: .membership,
            initialSecret: DemoSecret(label: "memberID", value: "111234567890"),
            additionalSecrets: [],
            attributes: [
                DemoAttribute(kind: .custom, name: "organization", value: "Costco Wholesale"),
                DemoAttribute(kind: .custom, name: "member name", value: "Jane Doe"),
                DemoAttribute(kind: .membershipTier, name: nil, value: "Executive"),
                DemoAttribute(kind: .expirationDate, name: nil, value: "2027-01-31"),
                DemoAttribute(kind: .custom, name: "home warehouse", value: "#482 - San Francisco")
            ],
            files: []
        ),
        DemoBlueprint(
            label: "Delta SkyMiles",
            type: .rewardsProgram,
            initialSecret: DemoSecret(label: "memberID", value: "2810123456"),
            additionalSecrets: [
                DemoSecret(label: "accountPassword", value: "fly-d3lta-2025!")
            ],
            attributes: [
                DemoAttribute(kind: .custom, name: "program", value: "Delta SkyMiles"),
                DemoAttribute(kind: .custom, name: "member name", value: "Jane Doe"),
                DemoAttribute(kind: .membershipTier, name: nil, value: "Gold Medallion"),
                DemoAttribute(kind: .custom, name: "points balance", value: "84,320 miles"),
                DemoAttribute(kind: .link, name: nil, value: "https://www.delta.com/skymiles"),
                DemoAttribute(kind: .associatedEmail, name: nil, value: "jane.doe@example.com")
            ],
            files: []
        )
    ]

    func ensureCredential(vaultID: Vault.ID, blueprint: DemoBlueprint) throws -> Credential.ID {
        let credentialID: Credential.ID
        if let existing = try findCredential(vaultID: vaultID, label: blueprint.label, type: blueprint.type) {
            credentialID = existing.id
        } else {
            let created = try createCredential(
                vaultID: vaultID,
                label: blueprint.label,
                type: blueprint.type,
                initialSecretLabel: blueprint.initialSecret.label,
                initialSecretPlaintext: Data(blueprint.initialSecret.value.utf8)
            )
            credentialID = created.credentialID
        }

        for secret in blueprint.additionalSecrets {
            if try !secretExists(credentialID: credentialID, label: secret.label) {
                _ = try addSecret(
                    credentialID: credentialID,
                    name: secret.label,
                    plaintext: Data(secret.value.utf8)
                )
            }
        }

        for attribute in blueprint.attributes {
            if try !attributeExists(
                credentialID: credentialID,
                kind: attribute.kind,
                name: attribute.name,
                value: attribute.value
            ) {
                _ = try addCredentialAttribute(
                    credentialID: credentialID,
                    kind: attribute.kind,
                    name: attribute.name,
                    value: attribute.value
                )
            }
        }

        for file in blueprint.files {
            if try !fileExists(credentialID: credentialID, label: file.label, fileName: file.fileName) {
                _ = try addSecretFile(
                    credentialID: credentialID,
                    label: file.label,
                    fileName: file.fileName,
                    mimeType: file.mimeType,
                    plaintext: file.plaintext()
                )
            }
        }

        return credentialID
    }

    func loadOrCreateVault(named name: String) throws -> Vault.ID {
        if let existing = try database.read({ db in
            try Vault.where { $0.name.eq(name) }.fetchOne(db)
        }) {
            return existing.id
        }
        return try createVault(name: name)
    }

    func findCredential(
        vaultID: Vault.ID,
        label: String,
        type: VaultItemType
    ) throws -> Credential? {
        try database.read { db in
            try VaultItem
                .where {
                    $0.vaultID.eq(vaultID)
                        && $0.title.eq(label)
                        && $0.type.eq(type)
                }
                .fetchOne(db)
        }
    }

    func secretExists(credentialID: Credential.ID, label: String) throws -> Bool {
        try database.read { db in
            try GenericItemSecretField
                .where { $0.itemID.eq(credentialID) && $0.fieldName.eq(label) }
                .fetchOne(db) != nil
        }
    }

    func attributeExists(
        credentialID: Credential.ID,
        kind: CredentialAttributeKind,
        name: String?,
        value: String
    ) throws -> Bool {
        let normalizedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = (normalizedName?.isEmpty == false)
            ? normalizedName!
            : kind.defaultAttributeName

        return try database.read { db in
            try CredentialAttribute
                .where {
                    $0.credentialID.eq(credentialID)
                        && $0.kindRawValue.eq(kind.rawValue)
                        && $0.name.eq(resolvedName)
                        && $0.value.eq(value)
                }
                .fetchOne(db) != nil
        }
    }

    func fileExists(
        credentialID: Credential.ID,
        label: String,
        fileName: String
    ) throws -> Bool {
        try database.read { db in
            try CredentialSecretFile
                .where {
                    $0.credentialID.eq(credentialID)
                        && $0.label.eq(label)
                        && $0.fileName.eq(fileName)
                }
                .fetchOne(db) != nil
        }
    }

    static func imageAssetData(named name: String) -> Data? {
        #if canImport(UIKit)
            guard let image = UIImage(named: name) else { return nil }
            return image.jpegData(compressionQuality: 1.0) ?? image.pngData()
        #elseif canImport(AppKit)
            guard let image = NSImage(named: NSImage.Name(name)),
                  let tiffData = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiffData)
            else { return nil }

            return rep.representation(
                using: .jpeg,
                properties: [.compressionFactor: 1.0]
            ) ?? rep.representation(using: .png, properties: [:])
        #else
            return nil
        #endif
    }
}
