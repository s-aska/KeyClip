//
//  Ring.swift
//  KeyClip
//
//  Created by Shinichiro Aska on 8/26/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

public extension KeyClip {
    enum KeyClipError: Error, CustomDebugStringConvertible {
        case stringEncoding
        case dataLoading
        case unhandledError(status: OSStatus)
        
        // /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/Security.framework/Headers/SecBase.h
        var message: String {
            switch self {
            case .stringEncoding:
                return "Failed to encode string to utf8"
                
            case .dataLoading:
                return "Failed to load data from keychain"
                
            case .unhandledError(let status):
                #if os(iOS)
                switch status {
                case errSecUnimplemented:
                    return "Function or operation not implemented."
                case errSecParam:
                    return "One or more parameters passed to a function where not valid."
                case errSecAllocate:
                    return "Failed to allocate memory."
                case errSecNotAvailable:
                    return "No keychain is available. You may need to restart your computer."
                case errSecDuplicateItem:
                    return "The specified item already exists in the keychain."
                case errSecItemNotFound:
                    return "The specified item could not be found in the keychain."
                case errSecInteractionNotAllowed:
                    return "User interaction is not allowed."
                case errSecDecode:
                    return "Unable to decode the provided data."
                case errSecAuthFailed:
                    return "The user name or passphrase you entered is not correct."
                case -25243: // errSecNoAccessForItem https://developer.apple.com/library/ios/samplecode/GenericKeychain/Listings/Classes_KeychainItemWrapper_m.html
                    return "Ignore the access group if running on the iPhone simulator."
                default:
                    return "Refer to SecBase.h for description (status:\(status))"
                }
                #elseif os(OSX)
                return "Refer to MacErrors.h for description (status:\(status))"
                #endif
            }
        }
        
        public var debugDescription: String {
            return message
        }
    }
    
    class Ring {
        let accessGroup: String?
        let service: String
        let accessible: String

        // MARK: Init

        init(accessGroup: String?, service: String, accessible: String) {
            self.accessGroup = accessGroup
            self.service = service
            self.accessible = accessible
        }

        // MARK: Exists

        open func exists(_ key: String) throws -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service as AnyObject,
                kSecClass       as String : kSecClassGenericPassword,
                kSecAttrAccount as String : key as AnyObject,
                kSecAttrGeneric as String : key as AnyObject ]

            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
            }

            let status = SecItemCopyMatching(query as CFDictionary, nil)

            switch status {
            case errSecSuccess:
                return true
            case errSecItemNotFound:
                return false
            default:
                throw KeyClipError.unhandledError(status: status)
            }
        }
        
        // MARK: - Saving

        open func save(data: Data, forKey key: String) throws {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service as AnyObject,
                kSecClass       as String : kSecClassGenericPassword,
                kSecAttrAccount as String : key as AnyObject,
                kSecAttrGeneric as String : key as AnyObject ]

            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
            }

            var status: OSStatus

            if try self.exists(key) {
                status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
            } else {
                query[kSecAttrAccessible as String] = self.accessible as AnyObject?
                query[kSecValueData as String] = data as AnyObject?
                status = SecItemAdd(query as CFDictionary, nil)
            }

            guard status == errSecSuccess else {
                throw KeyClipError.unhandledError(status: status)
            }
        }

        open func save(string: String, forKey key: String) throws {
            guard let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false) else {
                throw KeyClipError.stringEncoding
            }
            
            try save(data: data, forKey: key)
        }

        open func save(dictionary: [AnyHashable: Any], forKey key: String) throws {
            try save(data: try JSONSerialization.data(withJSONObject: dictionary, options: []), forKey: key)
        }
        
        // MARK: - Loading
        
        open func data(forKey key: String) throws -> Data? {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service as AnyObject,
                kSecClass       as String : kSecClassGenericPassword,
                kSecAttrAccount as String : key as AnyObject,
                kSecAttrGeneric as String : key as AnyObject,
                kSecReturnData  as String : kCFBooleanTrue,
                kSecMatchLimit  as String : kSecMatchLimitOne ]

            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
            }

            var result: AnyObject?
            let status = withUnsafeMutablePointer(to: &result) { SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0)) }

            guard status == errSecSuccess else {
                if status == errSecItemNotFound {
                    return nil
                }
                
                throw KeyClipError.unhandledError(status: status)
            }
            
            guard let data = result as? Data else {
                throw KeyClipError.dataLoading
            }

            return data
        }

        open func dictionary(forKey key: String) throws -> [AnyHashable: Any]? {
            guard let data = try data(forKey: key) else {
                return nil
            }
            
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            return json as? [AnyHashable: Any]
        }

        open func string(forKey key: String) throws -> String? {
            guard let data = try data(forKey: key) else {
                return nil
            }
            
            guard let string = String(data: data, encoding: .utf8) else {
                throw KeyClipError.stringEncoding
            }
            
            return string
        }

        // MARK: - Loading and converting
        
        open func load<T>(_ key: String, success: ([AnyHashable: Any]) -> T) throws -> T? {
            guard let dictionary = try dictionary(forKey: key) else {
                return nil
            }
            
            return success(dictionary)
        }
        
        // MARK: - Deleting

        @discardableResult
        open func delete(_ key: String) throws -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service as AnyObject,
                kSecClass       as String : kSecClassGenericPassword,
                kSecAttrAccount as String : key as AnyObject,
                kSecAttrGeneric as String : key as AnyObject ]

            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
            }

            let status = SecItemDelete(query as CFDictionary)

            guard status == errSecSuccess else {
                if status == errSecItemNotFound {
                    return false
                }
                
                throw KeyClipError.unhandledError(status: status)
            }
            
            return true
        }


        @discardableResult
        open func clear() throws -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service as AnyObject,
                kSecClass       as String : kSecClassGenericPassword ]

            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
            }

            let status = SecItemDelete(query as CFDictionary)
            
            guard status == errSecSuccess else {
                if status == errSecItemNotFound {
                    return false
                }
                
                throw KeyClipError.unhandledError(status: status)
            }
            
            return true
        }
    }
}
