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
        Singleton.defaultRing = Ring(group: Singleton.defaultRing.group, service: service, accessible: Singleton.defaultRing.accessible)
    }
    
    public class func setAccessible(accessible: String) {
        Singleton.defaultRing = Ring(group: Singleton.defaultRing.group, service: Singleton.defaultRing.service, accessible: accessible)
    }
    
    public class func setGroup(group: String) {
        Singleton.defaultRing = Ring(group: group, service: Singleton.defaultRing.service, accessible: Singleton.defaultRing.accessible)
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
    
    public class Builder {
        var group: String?
        var service: String = NSBundle.mainBundle().bundleIdentifier ?? "pw.aska.KeyClip"
        var accessible: String = kSecAttrAccessibleWhenUnlocked
        
        public init() {}
        
        public func group(group: String) -> Builder {
            self.group = group
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
            return Ring(group: group, service: service, accessible: accessible)
        }
    }
    
    public class Ring {
        
        let group: String?
        let service: String
        let accessible: String
        
        init(group: String?, service: String, accessible: String) {
            self.group = group
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
            
            if let group = self.group {
                query[kSecAttrAccessGroup] = group
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
            
            if let group = self.group {
                query[kSecAttrAccessGroup] = group
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
            
            if let group = self.group {
                query[kSecAttrAccessGroup] = group
            }
            
            let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
            
            return status == noErr
        }
        
        public func clear() -> Bool {
            var query: [String: AnyObject] = [
                kSecAttrService : self.service,
                kSecClass       : kSecClassGenericPassword
            ]
            
            if let group = self.group {
                query[kSecAttrAccessGroup] = group
            }
            
            let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
            
            return status == noErr
        }
    }
}
