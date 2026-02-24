import CryptoKit
import Dependencies
import Foundation

struct RecoveryWrapKeyDeriverClient: Sendable {
    var makeSalt: @Sendable (_ byteCount: Int) -> Data
    var derive: @Sendable (_ recoveryCode: String, _ salt: Data) throws -> SymmetricKey
}

extension RecoveryWrapKeyDeriverClient: DependencyKey {
    static var liveValue: RecoveryWrapKeyDeriverClient {
        RecoveryWrapKeyDeriverClient(
            makeSalt: { byteCount in
                RecoveryWrapKeyDeriver.makeSalt(byteCount: byteCount)
            },
            derive: { recoveryCode, salt in
                try RecoveryWrapKeyDeriver.derive(recoveryCode: recoveryCode, salt: salt)
            }
        )
    }

    static var testValue: RecoveryWrapKeyDeriverClient {
        RecoveryWrapKeyDeriverClient(
            makeSalt: { byteCount in
                Data(repeating: 0xA5, count: byteCount)
            },
            derive: { recoveryCode, salt in
                var material = Data("test-deriver-v1|".utf8)
                material.append(Data(recoveryCode.utf8))
                material.append(salt)
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
