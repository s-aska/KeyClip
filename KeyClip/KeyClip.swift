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
        var query: [String: AnyObject] = [
            kSecClass            : kSecClassGenericPassword,
            kSecAttrAccount      : "pw.aska.KeyClip.application-identifier-check",
            kSecReturnAttributes : kCFBooleanTrue ]
        
        var result: AnyObject?
        var status = withUnsafeMutablePointer(&result) { SecItemCopyMatching(query, UnsafeMutablePointer($0)) }
        
        if status == errSecItemNotFound {
            status = withUnsafeMutablePointer(&result) { SecItemAdd(query, UnsafeMutablePointer($0)) }
        }
        
        if status == errSecSuccess {
            if let dictionary = result as? NSDictionary {
                if let accessGroup = dictionary[kSecAttrAccessGroup as NSString] as? NSString {
                    SecItemDelete(query as CFDictionaryRef)
                    return accessGroup
                }
            }
        }
        
        assertionFailure("failure get application-identifier")
    }
}

// MARK: - Builder

public extension KeyClip {
    public class Builder {
        
        var accessGroup: String?
        var service: String = NSBundle.mainBundle().bundleIdentifier ?? "pw.aska.KeyClip"
        var accessible: String = kSecAttrAccessibleAfterFirstUnlock
        
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
        
        public func save(key: String, data: NSData, failure: ((NSError) -> Void)?) -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService    : self.service,
                kSecClass          : kSecClassGenericPassword,
                kSecAttrAccount    : key,
                kSecAttrGeneric    : key ]
            
            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup] = accessGroup
            }
            
            var status = SecItemCopyMatching(query, nil)
            
            if status == errSecSuccess {
                status = SecItemUpdate(query, [kSecValueData as String: data])
            } else if status == errSecItemNotFound {
                query[kSecAttrAccessible] = self.accessible
                query[kSecValueData] = data
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
            if let data = NSJSONSerialization.dataWithJSONObject(dictionary, options: nil, error: &error) {
                if let e = error {
                    self.failure(error: e, failure: failure)
                }
                return self.save(key, data: data, failure: failure)
            }
            return false
        }
        
        public func load(key: String, failure: ((NSError) -> Void)?) -> NSData? {
            var query: [String: AnyObject] = [
                kSecAttrService : self.service,
                kSecClass       : kSecClassGenericPassword,
                kSecAttrAccount : key,
                kSecAttrGeneric : key,
                kSecReturnData  : kCFBooleanTrue,
                kSecMatchLimit  : kSecMatchLimitOne ]
            
            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup] = accessGroup
            }
            
            var result: AnyObject?
            var status = withUnsafeMutablePointer(&result) { SecItemCopyMatching(query, UnsafeMutablePointer($0)) }
            
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
                if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) {
                    if let e = error {
                        self.failure(error: e, failure: failure)
                    }
                    return json as? NSDictionary
                }
            }
            return nil
        }
        
        public func load(key: String, failure: ((NSError) -> Void)?) -> String? {
            if let data: NSData = self.load(key, failure: failure) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string
                }
            }
            return nil
        }
        
        public func delete(key: String, failure: ((NSError) -> Void)?) -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService : self.service,
                kSecClass       : kSecClassGenericPassword,
                kSecAttrAccount : key,
                kSecAttrGeneric : key ]
            
            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup] = accessGroup
            }
            
            let status = SecItemDelete(query as CFDictionaryRef)
            
            if status == errSecSuccess {
                return true
            } else  if status != errSecItemNotFound {
                self.failure(status: status, failure: failure)
            }
            return false
        }
        
        public func clear(#failure: ((NSError) -> Void)?) -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService : self.service,
                kSecClass       : kSecClassGenericPassword ]
            
            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup] = accessGroup
            }
            
            let status = SecItemDelete(query as CFDictionaryRef)
            
            if status == errSecSuccess {
                return true
            } else {
                self.failure(status: status, failure: failure)
            }
            return false
        }
        
        // MARK: Private Methods
        
        private func failure(#status: OSStatus, failure: ((NSError) -> Void)?, function: String = __FUNCTION__, line: Int = __LINE__) {
            self.failure(error: NSError(domain: "pw.aska.KeyClip", code: Int(status), userInfo: nil), failure: failure, function: function, line: line)
        }
        
        private func failure(#error: NSError, failure: ((NSError) -> Void)?, function: String = __FUNCTION__, line: Int = __LINE__) {
            failure?(error)
            
            if Static.printError {
                NSLog("[KeyClip] function:\(function) line:\(line) \(error.debugDescription)")
            }
        }
    }
}

// MARK: - Public Methods for Xcode suggest

public extension KeyClip {
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
    
    public class func delete(key: String) -> Bool {
        return Static.instance.delete(key, failure: nil)
    }
    
    public class func clear() -> Bool {
        return Static.instance.clear(failure: nil)
    }
}

public extension KeyClip.Ring {
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
    
    public func delete(key: String) -> Bool {
        return self.delete(key, failure: nil)
    }
    
    public func clear() -> Bool {
        return self.clear(failure: nil)
    }
}
