//
//  OAuthCredential.swift
//  UIKitTesting
//
//  Created by Richard Witherspoon on 8/31/23.
//

import Foundation
import OSLog

let keychainAccessGroup = "UIKitTesting.fetchrewards.fetch"

final class OAuthCredential: NSObject, NSCoding {
    static let logger = Logger(subsystem: "com.testing", category: "OAuthCredential")
    @objc let accessToken: String?
    @objc let refreshToken: String?
    @objc let accessExpiration: String?
    @objc let refreshExpiration: String?
    @objc let userId: String?
    @objc let authSource: String?
    @objc var createdUserIndicator: Bool = false
    
    // MARK: - Initializer
    
    init(
        accessToken: String?,
        refreshToken: String?,
        accessExpireDate: String?,
        refreshExpireDate: String?,
        userId: String?,
        authSource: String?,
        createdUserIndicator: Bool = false
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accessExpiration = accessExpireDate
        self.refreshExpiration = refreshExpireDate
        self.userId = userId
        self.authSource = authSource
        self.createdUserIndicator = createdUserIndicator
    }
    
    required init?(coder aDecoder: NSCoder) {
        accessToken = aDecoder.decodeObject(forKey: CodingKeys.accessToken.rawValue) as? String
        refreshToken = aDecoder.decodeObject(forKey: CodingKeys.refreshToken.rawValue) as? String
        accessExpiration = aDecoder.decodeObject(forKey: CodingKeys.accessExpiration.rawValue) as? String
        refreshExpiration = aDecoder.decodeObject(forKey: CodingKeys.refreshExpiration.rawValue) as? String
        userId = aDecoder.decodeObject(forKey: CodingKeys.userId.rawValue) as? String
        authSource = aDecoder.decodeObject(forKey: CodingKeys.authSource.rawValue) as? String
    }
    
    // MARK: - Encoding
    
    private enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case accessExpiration
        case refreshExpiration
        case userId
        case authSource
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(accessToken, forKey: CodingKeys.accessToken.rawValue)
        aCoder.encode(refreshToken, forKey: CodingKeys.refreshToken.rawValue)
        aCoder.encode(accessExpiration, forKey: CodingKeys.accessExpiration.rawValue)
        aCoder.encode(refreshExpiration, forKey: CodingKeys.refreshExpiration.rawValue)
        aCoder.encode(userId, forKey: CodingKeys.userId.rawValue)
        aCoder.encode(authSource, forKey: CodingKeys.authSource.rawValue)
    }
    
    // MARK: - Public Helpers
    
    static func store(_ credential: OAuthCredential?, withIdentifier identifier: String) -> Bool {
        guard let queryDictionary: [String: Any] = keychainQueryDictionary(withIdentifier: identifier) as? [String: Any] else {
            logger.error("Should be of type [String: Any]")
            fatalError("Should be of type [String: Any]")
        }
        
        // setting credential to nil, just delete it and return
        guard let credential else {
            return deleteCredential(withIdentifier: identifier)
        }
        
        var updateDictionary = [String: Any]()
        
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: credential, requiringSecureCoding: false) {
            updateDictionary[kSecValueData as String] = data
        } else {
            logger.error("Unable to save credential data.")
        }
        
        updateDictionary[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        
        let exists = (retrieveCredential(withIdentifier: identifier) != nil)
        let status: OSStatus
        
        if exists {
            status = SecItemUpdate(queryDictionary as CFDictionary, updateDictionary as CFDictionary)
        } else {
            var combinedDictionary = queryDictionary
            combinedDictionary.merge(updateDictionary, uniquingKeysWith: { (_, new) in new })
            status = SecItemAdd(combinedDictionary as CFDictionary, nil)
        }
        
        if status != errSecSuccess {
            logger.info("Unable to \(exists ? "update" : "add", privacy: .public) credential with identifier \"\(identifier, privacy: .public)\" (Error \(status, privacy: .public))")
        } else {
            logger.info("Post notification refreshed")
        }
        
        return (status == errSecSuccess)
    }
    
    /// Retrieves Credentials using an identifier, returning a
    ///
    /// - Important: unarchiveTopLevelObjectWithData cannot be updated to the non-deprecated version without breaking this flow.
    static func retrieveCredential(withIdentifier identifier: String) -> OAuthCredential? {
        let queryDictionary = keychainQueryDictionary(withIdentifier: identifier)
        queryDictionary[kSecReturnData as String] = kCFBooleanTrue
        queryDictionary[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(queryDictionary as CFDictionary, &result)
        
        if status != errSecSuccess {
            if status != errSecItemNotFound {
                logger.error("Unable to fetch credential with identifier \"\(identifier, privacy: .public)\" (Error \(status, privacy: .public))")
            }
            return nil
        }
        
        guard
            let data = result as? Data,
            let credential = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? OAuthCredential,
            credential.userId != nil
        else {
            // if we don't have a valid user ID, delete this credential, it's an old version from an old app (this will make the user log in again)
            _ = deleteCredential(withIdentifier: identifier)
            return nil
        }
        
        logger.error("Set UserManager.currentUser.authSource")
        
        return credential
    }
    
    @discardableResult
    static func deleteCredential(withIdentifier identifier: String) -> Bool {
        let queryDictionary = keychainQueryDictionary(withIdentifier: identifier)
        
        let status = SecItemDelete(queryDictionary as CFDictionary)
        
        if status != errSecSuccess, status != errSecItemNotFound {
            logger.info("Unable to delete credential with identifier \"\(identifier, privacy: .public)\" (Error \(status, privacy: .public))")
        }
        
        return status == errSecSuccess
    }
    
    // MARK: - Private
    
    private static func keychainQueryDictionary(withIdentifier identifier: String) -> NSMutableDictionary {
        let queryDictionary: NSMutableDictionary = [
            kSecClass as String: kSecClassGenericPassword,
            //            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecAttrService as String: "AFOAuthCredentialService"
        ]
        
        queryDictionary.setValue(identifier, forKey: kSecAttrAccount as String)
        
        return queryDictionary
    }
    
    // MARK: - Mock
    
    static let mock = OAuthCredential(
        accessToken: "accessTokenSwift",
        refreshToken: "refreshTokenSwift",
        accessExpireDate: "accessExpireDateSwift",
        refreshExpireDate: "refreshExpireDateSwift",
        userId: "userIdSwift",
        authSource: "authSourceSwift"
    )
}