//
//  KeyClip.swift
//  KeyClip
//
//  Created by Shinichiro Aska on 11/29/14.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import Foundation
import Security

public class KeyClip {
    
    // MARK: Types
    
    private struct Static {
        private static let instance = Builder().build()
        private static var printError = false
    }
    
    // MARK: Public Methods
    
    public class func exists(key: String, failure: ((NSError) -> Void)?) -> Bool {
        return Static.instance.exists(key, failure: failure)
    }
    
    public class func save(key: String, data: NSData, failure: ((NSError) -> Void)?) -> Bool {
        return Static.instance.save(key, data: data, failure: failure)
    }
    
    public class func save(key: String, string: String, failure: ((NSError) -> Void)?) -> Bool {
        return Static.instance.save(key, string: string, failure: failure)
    }
    
    public class func save(key: String, dictionary: NSDictionary, failure: ((NSError) -> Void)?) -> Bool {
        return Static.instance.save(key, dictionary: dictionary, failure: failure)
    }
    
    public class func load(key: String, failure: ((NSError) -> Void)?) -> NSData? {
        return Static.instance.load(key, failure: failure)
    }
    
    public class func load(key: String, failure: ((NSError) -> Void)?) -> NSDictionary? {
        return Static.instance.load(key, failure: failure)
    }
    
    public class func load(key: String, failure: ((NSError) -> Void)?) -> String? {
        return Static.instance.load(key, failure: failure)
    }
    
    public class func load<T>(key: String, success: (NSDictionary) -> T, failure: ((NSError) -> Void)?) -> T? {
        return Static.instance.load(key, success: success, failure: failure)
    }
    
    public class func delete(key: String, failure: ((NSError) -> Void)?) -> Bool {
        return Static.instance.delete(key, failure: failure)
    }
    
    public class func clear(failure: ((NSError) -> Void)?) -> Bool {
        return Static.instance.clear(failure: failure)
    }
    
    public class func printError(printError: Bool) {
        Static.printError = printError
    }
    
    // MARK: Debug Methods
    
    public class func defaultAccessGroup() -> String {
        let query: [String: AnyObject] = [
            kSecClass            as String : kSecClassGenericPassword,
            kSecAttrAccount      as String : "pw.aska.KeyClip.application-identifier-check",
            kSecReturnAttributes as String : kCFBooleanTrue ]
        
        var result: AnyObject?
        var status = withUnsafeMutablePointer(&result) { SecItemCopyMatching(query, UnsafeMutablePointer($0)) }
        
        if status == errSecItemNotFound {
            status = withUnsafeMutablePointer(&result) { SecItemAdd(query, UnsafeMutablePointer($0)) }
        }
        
        if status == errSecSuccess {
            if let dictionary = result as? NSDictionary {
                if let accessGroup = dictionary[kSecAttrAccessGroup as NSString] as? NSString {
                    SecItemDelete(query as CFDictionaryRef)
                    return accessGroup as String
                }
            }
        }
        
        assertionFailure("failure get application-identifier")
        
        return ""
    }
}

// MARK: - Builder

public extension KeyClip {
    public class Builder {
        
        var accessGroup: String?
        var service: String = NSBundle.mainBundle().bundleIdentifier ?? "pw.aska.KeyClip"
        var accessible: String = kSecAttrAccessibleAfterFirstUnlock as String
        
        public init() {}
        
        public func accessGroup(accessGroup: String) -> Builder {
            self.accessGroup = accessGroup
            return self
        }
        
        public func service(service: String) -> Builder {
            self.service = service
            return self
        }
        
        public func accessible(accessible: String) -> Builder {
            self.accessible = accessible
            return self
        }
        
        public func build() -> Ring {
            return Ring(accessGroup: accessGroup, service: service, accessible: accessible)
        }
    }
}

// MARK: - Ring

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
        
        public func exists(key: String, failure: ((NSError) -> Void)?) -> Bool {
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
        
        public func save(key: String, data: NSData, failure: ((NSError) -> Void)?) -> Bool {
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
        
        public func save(key: String, string: String, failure: ((NSError) -> Void)?) -> Bool {
            if let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                return self.save(key, data: data, failure: failure)
            }
            return false
        }
        
        public func save(key: String, dictionary: NSDictionary, failure: ((NSError) -> Void)?) -> Bool {
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
        
        public func load(key: String, failure: ((NSError) -> Void)?) -> NSData? {
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
        
        public func load(key: String, failure: ((NSError) -> Void)?) -> NSDictionary? {
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
        
        public func load(key: String, failure: ((NSError) -> Void)?) -> String? {
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
        
        public func delete(key: String, failure: ((NSError) -> Void)?) -> Bool {
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
        
        public func clear(failure failure: ((NSError) -> Void)?) -> Bool {
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
            
            if Static.printError {
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
                return SecCopyErrorMessageString(status, nil).takeUnretainedValue() as String
            #endif
        }
    }
}

// MARK: - Public Methods for Xcode suggest

public extension KeyClip {
    public class func exists(key: String) -> Bool {
        return Static.instance.exists(key, failure: nil)
    }
    
    public class func save(key: String, data: NSData) -> Bool {
        return Static.instance.save(key, data: data, failure: nil)
    }
    
    public class func save(key: String, string: String) -> Bool {
        return Static.instance.save(key, string: string, failure: nil)
    }
    
    public class func save(key: String, dictionary: NSDictionary) -> Bool {
        return Static.instance.save(key, dictionary: dictionary, failure: nil)
    }
    
    public class func load(key: String) -> NSData? {
        return Static.instance.load(key, failure: nil)
    }
    
    public class func load(key: String) -> NSDictionary? {
        return Static.instance.load(key, failure: nil)
    }
    
    public class func load(key: String) -> String? {
        return Static.instance.load(key, failure: nil)
    }
    
    public class func load<T>(key: String, success: (NSDictionary) -> T) -> T? {
        return Static.instance.load(key, success: success, failure: nil)
    }
    
    public class func delete(key: String) -> Bool {
        return Static.instance.delete(key, failure: nil)
    }
    
    public class func clear() -> Bool {
        return Static.instance.clear(failure: nil)
    }
}

public extension KeyClip.Ring {
    public func exists(key: String) -> Bool {
        return self.exists(key, failure: nil)
    }
    
    public func save(key: String, data: NSData) -> Bool {
        return self.save(key, data: data, failure: nil)
    }
    
    public func save(key: String, string: String) -> Bool {
        return self.save(key, string: string, failure: nil)
    }
    
    public func save(key: String, dictionary: NSDictionary) -> Bool {
        return self.save(key, dictionary: dictionary, failure: nil)
    }
    
    public func load(key: String) -> NSData? {
        return self.load(key, failure: nil)
    }
    
    public func load(key: String) -> NSDictionary? {
        return self.load(key, failure: nil)
    }
    
    public func load(key: String) -> String? {
        return self.load(key, failure: nil)
    }
    
    public func load<T>(key: String, success: (NSDictionary) -> T) -> T? {
        return self.load(key, success: success, failure: nil)
    }
    
    public func delete(key: String) -> Bool {
        return self.delete(key, failure: nil)
    }
    
    public func clear() -> Bool {
        return self.clear(failure: nil)
    }
}
