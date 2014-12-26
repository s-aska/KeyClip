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
    
    private struct Singleton {
        private static var instance = Builder().build()
    }
    
    public class func save(key: String, data: NSData) -> Bool {
        return Singleton.instance.save(key, data: data)
    }
    
    public class func save(key: String, string: String) -> Bool {
        return Singleton.instance.save(key, string: string)
    }
    
    public class func save(key: String, dictionary: NSDictionary) -> Bool {
        return Singleton.instance.save(key, dictionary: dictionary)
    }
    
    public class func load(key: String) -> NSData? {
        return Singleton.instance.load(key)
    }
    
    public class func load(key: String) -> NSDictionary? {
        return Singleton.instance.load(key)
    }
    
    public class func load(key: String) -> String? {
        return Singleton.instance.load(key)
    }
    
    public class func delete(key: String) -> Bool {
        return Singleton.instance.delete(key)
    }
    
    public class func clear() -> Bool {
        return Singleton.instance.clear()
    }
    
    // for debug
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
    
    public class Builder {
        
        var accessGroup: String?
        var service: String = NSBundle.mainBundle().bundleIdentifier ?? "pw.aska.KeyClip"
        var accessible: String = kSecAttrAccessibleWhenUnlocked
        var printError = false
        var onError: ((NSError) -> ())? = nil
        
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
        
        public func printError(printError: Bool) -> Builder {
            self.printError = printError
            return self
        }
        
        public func onError(onError: ((NSError) -> ())?) -> Builder {
            self.onError = onError
            return self
        }
        
        public func build() -> Ring {
            return Ring(accessGroup: accessGroup, service: service, accessible: accessible, printError: printError, onError: onError)
        }
        
        public func buildDefault() {
            Singleton.instance = build()
        }
    }
    
    public class Ring {
        
        let accessGroup: String?
        let service: String
        let accessible: String
        let printError = false
        let onError: ((NSError) -> ())? = nil
        
        init(accessGroup: String?, service: String, accessible: String, printError: Bool, onError: ((NSError) -> ())?) {
            self.accessGroup = accessGroup
            self.service = service
            self.accessible = accessible
            self.printError = printError
            self.onError = onError
        }
        
        public func save(key: String, data: NSData) -> Bool {
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
                failure(error(status))
            }
            return false
        }
        
        public func save(key: String, string: String) -> Bool {
            if let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                return save(key, data: data)
            }
            return false
        }
        
        public func save(key: String, dictionary: NSDictionary) -> Bool {
            var error: NSError?
            if let data = NSJSONSerialization.dataWithJSONObject(dictionary, options: nil, error: &error) {
                if let e = error {
                    failure(e)
                }
                return save(key, data: data)
            }
            return false
        }
        
        public func load(key: String) -> NSData? {
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
                failure(error(status))
            }
            return nil
        }
        
        public func load(key: String) -> NSDictionary? {
            if let data: NSData = load(key) {
                if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) {
                    return json as? NSDictionary
                }
            }
            return nil
        }
        
        public func load(key: String) -> String? {
            if let data: NSData = load(key) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string
                }
            }
            return nil
        }
        
        public func delete(key: String) -> Bool {
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
                failure(error(status))
            }
            return false
        }
        
        public func clear() -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService : self.service,
                kSecClass       : kSecClassGenericPassword
            ]
            
            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup] = accessGroup
            }
            
            let status = SecItemDelete(query as CFDictionaryRef)
            
            if status == errSecSuccess {
                return true
            } else {
                failure(error(status))
            }
            return false
        }
        
        func error(status: OSStatus) -> NSError {
            return NSError(domain: "pw.aska.KeyClip", code: Int(status), userInfo: nil)
        }
        
        func failure(error: NSError, function: String = __FUNCTION__, line: Int = __LINE__) {
            onError?(error)
            
            if printError {
                NSLog("[KeyClip] function:\(function) line:\(line) \(error.debugDescription)")
            }
        }
    }
}
