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
    
    private struct Static {
        private static let instance = Builder().build()
        private static var printError = false
    }
    
    public class func save(key: String, data: NSData) -> Bool {
        return Static.instance.save(key, data: data)
    }
    
    public class func save(key: String, string: String) -> Bool {
        return Static.instance.save(key, string: string)
    }
    
    public class func save(key: String, dictionary: NSDictionary) -> Bool {
        return Static.instance.save(key, dictionary: dictionary)
    }
    
    public class func load(key: String) -> NSData? {
        return Static.instance.load(key)
    }
    
    public class func load(key: String) -> NSDictionary? {
        return Static.instance.load(key)
    }
    
    public class func load(key: String) -> String? {
        return Static.instance.load(key)
    }
    
    public class func delete(key: String) -> Bool {
        return Static.instance.delete(key)
    }
    
    public class func clear() -> Bool {
        return Static.instance.clear()
    }
    
    public class func handleError(handleError: ((NSError) -> Void)) -> Ring {
        return Static.instance.handleError(handleError)
    }
    
    public class func printError(printError: Bool) {
        Static.printError = printError
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
        
        return ""
//        assertionFailure("failure get application-identifier")
    }
    
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
    
    public class Ring {
        
        let accessGroup: String?
        let service: String
        let accessible: String
        let handleError: ((NSError) -> Void)?
        
        init(accessGroup: String?, service: String, accessible: String, handleError: ((NSError) -> Void)? = nil) {
            self.accessGroup = accessGroup
            self.service = service
            self.accessible = accessible
            self.handleError = handleError
        }
        
        public func handleError(handler: ((NSError) -> Void)) -> Ring {
            return Ring(accessGroup: accessGroup, service: service, accessible: accessible, handleError: handler)
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
                self.failure(status: status)
            }
            return false
        }
        
        public func save(key: String, string: String) -> Bool {
            if let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                return self.save(key, data: data)
            }
            return false
        }
        
        public func save(key: String, dictionary: NSDictionary) -> Bool {
            var error: NSError?
            if let data = NSJSONSerialization.dataWithJSONObject(dictionary, options: nil, error: &error) {
                if let e = error {
                    self.failure(error: e)
                }
                return self.save(key, data: data)
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
                self.failure(status: status)
            }
            return nil
        }
        
        public func load(key: String) -> NSDictionary? {
            var error: NSError?
            if let data: NSData = self.load(key) {
                if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) {
                    if let e = error {
                        self.failure(error: e)
                    }
                    return json as? NSDictionary
                }
            }
            return nil
        }
        
        public func load(key: String) -> String? {
            if let data: NSData = self.load(key) {
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
                self.failure(status: status)
            }
            return false
        }
        
        public func clear() -> Bool {
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
                self.failure(status: status)
            }
            return false
        }
        
        private func failure(#status: OSStatus, function: String = __FUNCTION__, line: Int = __LINE__) {
            self.failure(error: NSError(domain: "pw.aska.KeyClip", code: Int(status), userInfo: nil), function: function, line: line)
        }
        
        private func failure(#error: NSError, function: String = __FUNCTION__, line: Int = __LINE__) {
            self.handleError?(error)
            
            if Static.printError {
                NSLog("[KeyClip] function:\(function) line:\(line) \(error.debugDescription)")
            }
        }
    }
}
