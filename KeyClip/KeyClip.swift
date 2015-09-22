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
        private static let instance = KeyClip.Builder().build()
        private static var printError = false
    }
    
    public class var printError: Bool {
        return Static.printError
    }
    
    // MARK: Public Methods
    
    public class func exists(key: String, failure: ((NSError) -> Void)? = nil) -> Bool {
        return Static.instance.exists(key, failure: failure)
    }
    
    public class func save(key: String, data: NSData, failure: ((NSError) -> Void)? = nil) -> Bool {
        return Static.instance.save(key, data: data, failure: failure)
    }
    
    public class func save(key: String, string: String, failure: ((NSError) -> Void)? = nil) -> Bool {
        return Static.instance.save(key, string: string, failure: failure)
    }
    
    public class func save(key: String, dictionary: NSDictionary, failure: ((NSError) -> Void)? = nil) -> Bool {
        return Static.instance.save(key, dictionary: dictionary, failure: failure)
    }
    
    public class func load(key: String, failure: ((NSError) -> Void)? = nil) -> NSData? {
        return Static.instance.load(key, failure: failure)
    }
    
    public class func load(key: String, failure: ((NSError) -> Void)? = nil) -> NSDictionary? {
        return Static.instance.load(key, failure: failure)
    }
    
    public class func load(key: String, failure: ((NSError) -> Void)? = nil) -> String? {
        return Static.instance.load(key, failure: failure)
    }
    
    public class func load<T>(key: String, success: (NSDictionary) -> T, failure: ((NSError) -> Void)?) -> T? {
        return Static.instance.load(key, success: success, failure: failure)
    }
    
    public class func load<T>(key: String, success: (NSDictionary) -> T) -> T? {
        return Static.instance.load(key, success: success, failure: nil)
    }
    
    public class func delete(key: String, failure: ((NSError) -> Void)? = nil) -> Bool {
        return Static.instance.delete(key, failure: failure)
    }
    
    public class func clear(failure: ((NSError) -> Void)? = nil) -> Bool {
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
