//
//  File.swift
//  Testing
//
//  Created by Ricky on 12/21/24.
//

import Foundation
import CryptoKit

// Hashing Extension
extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
