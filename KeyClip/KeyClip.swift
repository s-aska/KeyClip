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
    
    private struct Settings {
        private static var service = NSBundle.mainBundle().bundleIdentifier ?? "pw.aska.KeyClip"
    }
    
    public class func setService(service: String) {
        Settings.service = service
    }
    
    public class func save(key: String, data: NSData) -> Bool {
        let query: [String: AnyObject] = [
            kSecAttrService : Settings.service,
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key,
            kSecAttrGeneric : key,
            kSecValueData   : data ]
        
        SecItemDelete(query as CFDictionaryRef)
        
        let status: OSStatus = SecItemAdd(query as CFDictionaryRef, nil)
        
        return status == noErr
    }
    
    public class func save(key: String, string: String) -> Bool {
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            return save(key, data: data)
        }
        return false
    }
    
    public class func save(key: String, dictionary: NSDictionary) -> Bool {
        if let data = NSJSONSerialization.dataWithJSONObject(dictionary, options: nil, error: nil) {
            return save(key, data: data)
        }
        return false
    }
    
    public class func load(key: String) -> NSData? {
        let query: [String: AnyObject] = [
            kSecAttrService : Settings.service,
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key,
            kSecAttrGeneric : key,
            kSecReturnData  : kCFBooleanTrue,
            kSecMatchLimit  : kSecMatchLimitOne ]
        
        var dataTypeRef :Unmanaged<AnyObject>?
        
        let status: OSStatus = SecItemCopyMatching(query, &dataTypeRef)
        
        if status == noErr {
            return (dataTypeRef!.takeRetainedValue() as NSData)
        } else {
            return nil
        }
    }
    
    public class func load(key: String) -> NSDictionary? {
        if let data: NSData = load(key) {
            if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) {
                return json as? NSDictionary
            }
        }
        return nil
    }
    
    public class func load(key: String) -> String? {
        if let data: NSData = load(key) {
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                return string
            }
        }
        return nil
    }
    
    public class func delete(key: String) -> Bool {
        let query: [String: AnyObject] = [
            kSecAttrService : Settings.service,
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key,
            kSecAttrGeneric : key ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
        
        return status == noErr
    }
    
    public class func clear() -> Bool {
        let query: [String: AnyObject] = [
            kSecAttrService : Settings.service,
            kSecClass       : kSecClassGenericPassword
        ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
        
        return status == noErr
    }
    
}
