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
        
        public func exists(key: String, failure: ((NSError) -> Void)? = nil) -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service,
                kSecClass       as String : kSecClassGenericPassword,
                kSecAttrAccount as String : key,
                kSecAttrGeneric as String : key ]
            
            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }
            
            let status = SecItemCopyMatching(query, nil)
            
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
        
        public func save(key: String, data: NSData, failure: ((NSError) -> Void)? = nil) -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service,
                kSecClass       as String : kSecClassGenericPassword,
                kSecAttrAccount as String : key,
                kSecAttrGeneric as String : key ]
            
            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }
            
            var status: OSStatus
            
            if self.exists(key, failure: failure) {
                status = SecItemUpdate(query, [kSecValueData as String: data])
            } else {
                query[kSecAttrAccessible as String] = self.accessible
                query[kSecValueData as String] = data
                status = SecItemAdd(query as CFDictionaryRef, nil)
            }
            
            if status == errSecSuccess {
                return true
            } else {
                self.failure(status: status, failure: failure)
            }
            return false
        }
        
        public func save(key: String, string: String, failure: ((NSError) -> Void)? = nil) -> Bool {
            if let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                return self.save(key, data: data, failure: failure)
            }
            return false
        }
        
        public func save(key: String, dictionary: NSDictionary, failure: ((NSError) -> Void)? = nil) -> Bool {
            var error: NSError?
            do {
                let data = try NSJSONSerialization.dataWithJSONObject(dictionary, options: [])
                if let e = error {
                    self.failure(error: e, failure: failure)
                }
                return self.save(key, data: data, failure: failure)
            } catch let error1 as NSError {
                error = error1
            }
            return false
        }
        
        public func load(key: String, failure: ((NSError) -> Void)? = nil) -> NSData? {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service,
                kSecClass       as String : kSecClassGenericPassword,
                kSecAttrAccount as String : key,
                kSecAttrGeneric as String : key,
                kSecReturnData  as String : kCFBooleanTrue,
                kSecMatchLimit  as String : kSecMatchLimitOne ]
            
            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }
            
            var result: AnyObject?
            let status = withUnsafeMutablePointer(&result) { SecItemCopyMatching(query, UnsafeMutablePointer($0)) }
            
            if status == errSecSuccess {
                if let data = result as? NSData {
                    return data
                }
            } else if status != errSecItemNotFound {
                self.failure(status: status, failure: failure)
            }
            return nil
        }
        
        public func load(key: String, failure: ((NSError) -> Void)? = nil) -> NSDictionary? {
            var error: NSError?
            if let data: NSData = self.load(key, failure: failure) {
                do {
                    let json: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                    if let e = error {
                        self.failure(error: e, failure: failure)
                    }
                    return json as? NSDictionary
                } catch let error1 as NSError {
                    error = error1
                }
            }
            return nil
        }
        
        public func load(key: String, failure: ((NSError) -> Void)? = nil) -> String? {
            if let data: NSData = self.load(key, failure: failure) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
            }
            return nil
        }
        
        public func load<T>(key: String, success: (NSDictionary) -> T, failure: ((NSError) -> Void)?) -> T? {
            if let dictionary: NSDictionary = self.load(key) {
                return success(dictionary)
            }
            return nil
        }
        
        public func load<T>(key: String, success: (NSDictionary) -> T) -> T? {
            return self.load(key, success: success, failure: nil)
        }
        
        public func delete(key: String, failure: ((NSError) -> Void)? = nil) -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service,
                kSecClass       as String : kSecClassGenericPassword,
                kSecAttrAccount as String : key,
                kSecAttrGeneric as String : key ]
            
            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }
            
            let status = SecItemDelete(query as CFDictionaryRef)
            
            if status == errSecSuccess {
                return true
            } else  if status != errSecItemNotFound {
                self.failure(status: status, failure: failure)
            }
            return false
        }
        
        public func clear(failure failure: ((NSError) -> Void)? = nil) -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService as String : self.service,
                kSecClass       as String : kSecClassGenericPassword ]
            
            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }
            
            let status = SecItemDelete(query as CFDictionaryRef)
            
            if status == errSecSuccess {
                return true
            } else  if status != errSecItemNotFound {
                self.failure(status: status, failure: failure)
            }
            return false
        }
        
        // MARK: Private Methods
        
        private func failure(status status: OSStatus, function: String = __FUNCTION__, line: Int = __LINE__, failure: ((NSError) -> Void)?) {
            let userInfo = [ NSLocalizedDescriptionKey : statusMessage(status) ]
            self.failure(error: NSError(domain: "pw.aska.KeyClip", code: Int(status), userInfo: userInfo), function: function, line: line, failure: failure)
        }
        
        private func failure(error error: NSError, function: String = __FUNCTION__, line: Int = __LINE__, failure: ((NSError) -> Void)?) {
            failure?(error)
            
            if KeyClip.printError {
                NSLog("[KeyClip] function:\(function) line:\(line) \(error.debugDescription)")
            }
        }
        
        // /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/Security.framework/Headers/SecBase.h
        private func statusMessage(status: OSStatus) -> String {
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
