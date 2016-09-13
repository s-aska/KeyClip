//
//  Ring.swift
//  KeyClip
//
//  Created by Shinichiro Aska on 8/26/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

public extension KeyClip {
    public class Ring {

        let accessGroup: String?
        let service: String
        let accessible: String

        // MARK: Initializer

        init(accessGroup: String?, service: String, accessible: String) {
            self.accessGroup = accessGroup
            self.service = service
            self.accessible = accessible
        }

        // MARK: Public Methods

        open func exists(_ key: String, failure: ((NSError) -> Void)? = nil) -> Bool {
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
                self.failure(status: status, failure: failure)
                return false
            }
        }

        open func save(_ key: String, data: Data, failure: ((NSError) -> Void)? = nil) -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service as AnyObject,
                kSecClass       as String : kSecClassGenericPassword,
                kSecAttrAccount as String : key as AnyObject,
                kSecAttrGeneric as String : key as AnyObject ]

            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
            }

            var status: OSStatus

            if self.exists(key, failure: failure) {
                status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
            } else {
                query[kSecAttrAccessible as String] = self.accessible as AnyObject?
                query[kSecValueData as String] = data as AnyObject?
                status = SecItemAdd(query as CFDictionary, nil)
            }

            switch status {
            case errSecSuccess:
                return true
            default:
                self.failure(status: status, failure: failure)
                return false
            }
        }

        open func save(_ key: String, string: String, failure: ((NSError) -> Void)? = nil) -> Bool {
            if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                return self.save(key, data: data, failure: failure)
            }
            return false
        }

        open func save(_ key: String, dictionary: NSDictionary, failure: ((NSError) -> Void)? = nil) -> Bool {
            do {
                let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
                return self.save(key, data: data, failure: failure)
            } catch let error as NSError {
                self.failure(error: error, failure: failure)
            }
            return false
        }

        open func load(_ key: String, failure: ((NSError) -> Void)? = nil) -> Data? {
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

            switch status {
            case errSecSuccess:
                if let data = result as? Data {
                    return data
                }
                return nil
            case errSecItemNotFound:
                return nil
            default:
                self.failure(status: status, failure: failure)
                return nil
            }
        }

        open func load(_ key: String, failure: ((NSError) -> Void)? = nil) -> NSDictionary? {
            if let data: Data = self.load(key, failure: failure) {
                do {
                    let json: Any = try JSONSerialization.jsonObject(with: data, options: [])
                    return json as? NSDictionary
                } catch let error as NSError {
                    self.failure(error: error, failure: failure)
                }
            }
            return nil
        }

        open func load(_ key: String, failure: ((NSError) -> Void)? = nil) -> String? {
            if let data: Data = self.load(key, failure: failure) {
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    return string as String
                }
            }
            return nil
        }

        open func load<T>(_ key: String, success: (NSDictionary) -> T, failure: ((NSError) -> Void)?) -> T? {
            if let dictionary: NSDictionary = self.load(key) {
                return success(dictionary)
            }
            return nil
        }

        open func load<T>(_ key: String, success: (NSDictionary) -> T) -> T? {
            return self.load(key, success: success, failure: nil)
        }

        open func delete(_ key: String, failure: ((NSError) -> Void)? = nil) -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service as AnyObject,
                kSecClass       as String : kSecClassGenericPassword,
                kSecAttrAccount as String : key as AnyObject,
                kSecAttrGeneric as String : key as AnyObject ]

            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
            }

            let status = SecItemDelete(query as CFDictionary)

            switch status {
            case errSecSuccess:
                return true
            case errSecItemNotFound:
                return false
            default:
                self.failure(status: status, failure: failure)
                return false
            }
        }

        open func clear(_ failure: ((NSError) -> Void)? = nil) -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service as AnyObject,
                kSecClass       as String : kSecClassGenericPassword ]

            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
            }

            let status = SecItemDelete(query as CFDictionary)

            switch status {
            case errSecSuccess:
                return true
            case errSecItemNotFound:
                return false
            default:
                self.failure(status: status, failure: failure)
                return false
            }
        }

        // MARK: Private Methods

        fileprivate func failure(status: OSStatus, function: String = #function, line: Int = #line, failure: ((NSError) -> Void)?) {
            let userInfo = [ NSLocalizedDescriptionKey : statusMessage(status) ]
            self.failure(error: NSError(domain: "pw.aska.KeyClip", code: Int(status), userInfo: userInfo), function: function, line: line, failure: failure)
        }

        fileprivate func failure(error: NSError, function: String = #function, line: Int = #line, failure: ((NSError) -> Void)?) {
            failure?(error)

            if KeyClip.printError {
                NSLog("[KeyClip] function:\(function) line:\(line) \(error.debugDescription)")
            }
        }

        // /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/Security.framework/Headers/SecBase.h
        // swiftlint:disable:next cyclomatic_complexity
        fileprivate func statusMessage(_ status: OSStatus) -> String {
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
}
