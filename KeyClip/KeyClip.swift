//
//  KeyClip.swift
//  KeyClip
//
//  Created by Shinichiro Aska on 11/29/14.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit
import Security

public class KeyClip {
    
    class func service() -> String {
        return NSBundle.mainBundle().bundleIdentifier ?? "pw.aska.KeyClip"
    }
    
    public class func save(key: String, data: NSData) -> Bool {
        let query = [
            kSecAttrService as String : service(),
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecAttrGeneric as String : key,
            kSecValueData as String   : data ]
        
        SecItemDelete(query as CFDictionaryRef)
        
        let status: OSStatus = SecItemAdd(query as CFDictionaryRef, nil)
        
        return status == noErr
    }
    
    public class func load(key: String) -> NSData? {
        let query = [
            kSecAttrService as String : service(),
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecAttrGeneric as String : key,
            kSecReturnData as String  : kCFBooleanTrue,
            kSecMatchLimit as String  : kSecMatchLimitOne ]
        
        var dataTypeRef :Unmanaged<AnyObject>?
        
        let status: OSStatus = SecItemCopyMatching(query, &dataTypeRef)
        
        if status == noErr {
            return (dataTypeRef!.takeRetainedValue() as NSData)
        } else {
            return nil
        }
    }
    
    public class func delete(key: String) -> Bool {
        let query = [
            kSecAttrService as String : service(),
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecAttrGeneric as String : key ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
        
        return status == noErr
    }
    
    public class func clear() -> Bool {
        let query = [
            kSecAttrService as String : service(),
            kSecClass as String : kSecClassGenericPassword
        ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
        
        return status == noErr
    }
    
}
