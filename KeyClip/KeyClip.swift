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
        private static var defaultRing = Builder().build()
    }
    
    public class func setService(service: String) {
        Singleton.defaultRing = Ring(accessGroup: Singleton.defaultRing.accessGroup, service: service, accessible: Singleton.defaultRing.accessible)
    }
    
    public class func setAccessible(accessible: String) {
        Singleton.defaultRing = Ring(accessGroup: Singleton.defaultRing.accessGroup, service: Singleton.defaultRing.service, accessible: accessible)
    }
    
    public class func setAccessGroup(accessGroup: String) {
        Singleton.defaultRing = Ring(accessGroup: accessGroup, service: Singleton.defaultRing.service, accessible: Singleton.defaultRing.accessible)
    }
    
    public class func save(key: String, data: NSData) -> Bool {
        return Singleton.defaultRing.save(key, data: data)
    }
    
    public class func save(key: String, string: String) -> Bool {
        return Singleton.defaultRing.save(key, string: string)
    }
    
    public class func save(key: String, dictionary: NSDictionary) -> Bool {
        return Singleton.defaultRing.save(key, dictionary: dictionary)
    }
    
    public class func load(key: String) -> NSData? {
        return Singleton.defaultRing.load(key)
    }
    
    public class func load(key: String) -> NSDictionary? {
        return Singleton.defaultRing.load(key)
    }
    
    public class func load(key: String) -> String? {
        return Singleton.defaultRing.load(key)
    }
    
    public class func delete(key: String) -> Bool {
        return Singleton.defaultRing.delete(key)
    }
    
    public class func clear() -> Bool {
        return Singleton.defaultRing.clear()
    }
    
    // for DEBUG
    public class func defaultAccessGroup() -> String {
        var query: [String: AnyObject] = [
            kSecClass            : kSecClassGenericPassword,
            kSecAttrAccount      : "application-identifier-check",
            kSecReturnAttributes : kCFBooleanTrue ]
        
        var dataTypeRef :Unmanaged<AnyObject>?
        var status: OSStatus = SecItemCopyMatching(query as CFDictionaryRef, &dataTypeRef)
        
        if status == errSecItemNotFound {
            status = SecItemAdd(query as CFDictionaryRef, &dataTypeRef);
        }
        
        if status == noErr {
            if let op = dataTypeRef?.toOpaque() {
                let resultDict: NSDictionary = Unmanaged<NSDictionary>.fromOpaque(op).takeUnretainedValue()
                
                if let accessGroup = resultDict[kSecAttrAccessGroup as NSString] as? NSString {
                    remove("application-identifier-check")
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
            self.service = accessible
            return self
        }
        
        public func build() -> Ring {
            return Ring(accessGroup: accessGroup, service: service, accessible: accessible)
        }
        
        public func buildDefault() {
            Singleton.defaultRing = build()
        }
    }
    
    public class Ring {
        
        let accessGroup: String?
        let service: String
        let accessible: String
        
        init(accessGroup: String?, service: String, accessible: String) {
            self.accessGroup = accessGroup
            self.service = service
            self.accessible = accessible
        }
        
        public func save(key: String, data: NSData) -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService    : self.service,
                kSecAttrAccessible : self.accessible,
                kSecClass          : kSecClassGenericPassword,
                kSecAttrAccount    : key,
                kSecAttrGeneric    : key,
                kSecValueData      : data ]
            
            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup] = accessGroup
            }
            
            SecItemDelete(query as CFDictionaryRef)
            
            let status: OSStatus = SecItemAdd(query as CFDictionaryRef, nil)
            
            return status == noErr
        }
        
        public func save(key: String, string: String) -> Bool {
            if let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                return save(key, data: data)
            }
            return false
        }
        
        public func save(key: String, dictionary: NSDictionary) -> Bool {
            if let data = NSJSONSerialization.dataWithJSONObject(dictionary, options: nil, error: nil) {
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
            
            var dataTypeRef :Unmanaged<AnyObject>?
            
            let status: OSStatus = SecItemCopyMatching(query, &dataTypeRef)
            
            if status == noErr {
                return (dataTypeRef!.takeRetainedValue() as NSData)
            } else {
                return nil
            }
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
            
            let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
            
            return status == noErr
        }
        
        public func clear() -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService : self.service,
                kSecClass       : kSecClassGenericPassword
            ]
            
            if let accessGroup = self.accessGroup {
                query[kSecAttrAccessGroup] = accessGroup
            }
            
            let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
            
            return status == noErr
        }
    }
}
