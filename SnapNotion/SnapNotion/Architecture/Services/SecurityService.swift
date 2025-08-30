//
//  SecurityService.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import Security
import CryptoKit

// MARK: - Security Service Protocol
protocol SecurityServiceProtocol {
    func encryptData(_ data: Data) throws -> EncryptedData
    func decryptData(_ encryptedData: EncryptedData) throws -> Data
    func generateSecureKey() throws -> SymmetricKey
    func storeKeyInKeychain(_ key: SymmetricKey, identifier: String) throws
    func retrieveKeyFromKeychain(identifier: String) throws -> SymmetricKey?
}

// MARK: - Security Service Implementation
class SecurityService: SecurityServiceProtocol {
    
    static let shared = SecurityService()
    
    // MARK: - Constants
    private enum Constants {
        static let keychainService = "com.snapnotion.app.encryption"
        static let keyLength = 32 // 256-bit key
    }
    
    // MARK: - Encryption Methods
    func encryptData(_ data: Data) throws -> EncryptedData {
        // Generate a new symmetric key for each encryption
        let key = SymmetricKey(size: .bits256)
        
        // Encrypt the data
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        let encryptedData = sealedBox.ciphertext
        let tag = sealedBox.tag
        let nonce = sealedBox.nonce
        
        // Store the key securely in keychain with a unique identifier
        let keyIdentifier = UUID().uuidString
        try storeKeyInKeychain(key, identifier: keyIdentifier)
        
        return EncryptedData(
            encryptedContent: encryptedData,
            nonce: Data(nonce),
            tag: tag,
            keyIdentifier: keyIdentifier
        )
    }
    
    func decryptData(_ encryptedData: EncryptedData) throws -> Data {
        // Retrieve the key from keychain
        guard let key = try retrieveKeyFromKeychain(identifier: encryptedData.keyIdentifier) else {
            throw SecurityError.keyNotFound
        }
        
        // Reconstruct the sealed box
        guard let nonce = try? AES.GCM.Nonce(data: encryptedData.nonce) else {
            throw SecurityError.invalidNonce
        }
        
        let sealedBox = try AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: encryptedData.encryptedContent,
            tag: encryptedData.tag
        )
        
        // Decrypt the data
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return decryptedData
    }
    
    func generateSecureKey() throws -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    // MARK: - Keychain Operations
    func storeKeyInKeychain(_ key: SymmetricKey, identifier: String) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw SecurityError.keychainStoreFailed(status)
        }
    }
    
    func retrieveKeyFromKeychain(identifier: String) throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let keyData = result as? Data else {
                throw SecurityError.invalidKeyData
            }
            return SymmetricKey(data: keyData)
            
        case errSecItemNotFound:
            return nil
            
        default:
            throw SecurityError.keychainRetrieveFailed(status)
        }
    }
    
    // MARK: - Utility Methods
    func deleteKeyFromKeychain(identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: identifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecurityError.keychainDeleteFailed(status)
        }
    }
    
    func clearAllKeys() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecurityError.keychainClearFailed(status)
        }
    }
}

// MARK: - Encrypted Data Structure
struct EncryptedData: Codable {
    let encryptedContent: Data
    let nonce: Data
    let tag: Data
    let keyIdentifier: String
    let encryptedAt: Date
    
    init(encryptedContent: Data, nonce: Data, tag: Data, keyIdentifier: String) {
        self.encryptedContent = encryptedContent
        self.nonce = nonce
        self.tag = tag
        self.keyIdentifier = keyIdentifier
        self.encryptedAt = Date()
    }
}

// MARK: - Security Errors
enum SecurityError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case keyNotFound
    case invalidNonce
    case invalidKeyData
    case keychainStoreFailed(OSStatus)
    case keychainRetrieveFailed(OSStatus)
    case keychainDeleteFailed(OSStatus)
    case keychainClearFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .keyNotFound:
            return "Encryption key not found in keychain"
        case .invalidNonce:
            return "Invalid encryption nonce"
        case .invalidKeyData:
            return "Invalid key data retrieved from keychain"
        case .keychainStoreFailed(let status):
            return "Failed to store key in keychain (status: \(status))"
        case .keychainRetrieveFailed(let status):
            return "Failed to retrieve key from keychain (status: \(status))"
        case .keychainDeleteFailed(let status):
            return "Failed to delete key from keychain (status: \(status))"
        case .keychainClearFailed(let status):
            return "Failed to clear keys from keychain (status: \(status))"
        }
    }
}

