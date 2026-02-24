import CryptoKit
import Dependencies
import Foundation

struct RecoveryWrapKeyDeriverClient: Sendable {
    var makeSalt: @Sendable (_ byteCount: Int) -> Data
    var defaultVersion: @Sendable () -> RecoveryWrapKeyDerivationVersion
    var derive: @Sendable (_ recoveryCode: String, _ salt: Data) throws -> SymmetricKey
    var deriveWithVersion: @Sendable (
        _ recoveryCode: String,
        _ salt: Data,
        _ version: RecoveryWrapKeyDerivationVersion
    ) throws -> SymmetricKey

    init(
        makeSalt: @escaping @Sendable (_ byteCount: Int) -> Data,
        defaultVersion: @escaping @Sendable () -> RecoveryWrapKeyDerivationVersion,
        derive: @escaping @Sendable (_ recoveryCode: String, _ salt: Data) throws -> SymmetricKey,
        deriveWithVersion: (
            @Sendable (
                _ recoveryCode: String,
                _ salt: Data,
                _ version: RecoveryWrapKeyDerivationVersion
            ) throws -> SymmetricKey
        )? = nil
    ) {
        self.makeSalt = makeSalt
        self.defaultVersion = defaultVersion
        self.derive = derive
        self.deriveWithVersion = deriveWithVersion ?? { recoveryCode, salt, _ in
            try derive(recoveryCode, salt)
        }
    }
}

extension RecoveryWrapKeyDeriverClient: DependencyKey {
    static var liveValue: RecoveryWrapKeyDeriverClient {
        RecoveryWrapKeyDeriverClient(
            makeSalt: { byteCount in
                RecoveryWrapKeyDeriver.makeSalt(byteCount: byteCount)
            },
            defaultVersion: {
                .current
            },
            derive: { recoveryCode, salt in
                try RecoveryWrapKeyDeriver.derive(recoveryCode: recoveryCode, salt: salt)
            },
            deriveWithVersion: { recoveryCode, salt, version in
                try RecoveryWrapKeyDeriver.derive(
                    recoveryCode: recoveryCode,
                    salt: salt,
                    version: version
                )
            }
        )
    }

    static var testValue: RecoveryWrapKeyDeriverClient {
        RecoveryWrapKeyDeriverClient(
            makeSalt: { byteCount in
                Data(repeating: 0xA5, count: byteCount)
            },
            defaultVersion: {
                .current
            },
            derive: { recoveryCode, salt in
                var material = Data("test-deriver-v1|".utf8)
                material.append(Data(recoveryCode.utf8))
                material.append(salt)
                let digest = SHA256.hash(data: material)
                return SymmetricKey(data: Data(digest))
            },
            deriveWithVersion: { recoveryCode, salt, version in
                var material = Data("test-deriver-v2|".utf8)
                material.append(Data(recoveryCode.utf8))
                material.append(salt)
                var versionBE = version.rawValue.bigEndian
                withUnsafeBytes(of: &versionBE) { bytes in
                    material.append(contentsOf: bytes)
                }
                let digest = SHA256.hash(data: material)
                return SymmetricKey(data: Data(digest))
            }
        )
    }
}

extension DependencyValues {
    var recoveryWrapKeyDeriver: RecoveryWrapKeyDeriverClient {
        get { self[RecoveryWrapKeyDeriverClient.self] }
        set { self[RecoveryWrapKeyDeriverClient.self] = newValue }
    }
}
