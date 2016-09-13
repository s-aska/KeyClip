//
//  KeyClip.swift
//  KeyClip
//
//  Created by Shinichiro Aska on 11/29/14.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import Foundation
import Security

open class KeyClip {

    // MARK: Types

    fileprivate struct Static {
        fileprivate static let instance = KeyClip.Builder().build()
        fileprivate static var printError = false
    }

    open class var printError: Bool {
        return Static.printError
    }

    // MARK: Public Methods

    open class func exists(_ key: String, failure: ((NSError) -> Void)? = nil) -> Bool {
        return Static.instance.exists(key, failure: failure)
    }

    open class func save(_ key: String, data: Data, failure: ((NSError) -> Void)? = nil) -> Bool {
        return Static.instance.save(key, data: data, failure: failure)
    }

    open class func save(_ key: String, string: String, failure: ((NSError) -> Void)? = nil) -> Bool {
        return Static.instance.save(key, string: string, failure: failure)
    }

    open class func save(_ key: String, dictionary: NSDictionary, failure: ((NSError) -> Void)? = nil) -> Bool {
        return Static.instance.save(key, dictionary: dictionary, failure: failure)
    }

    open class func load(_ key: String, failure: ((NSError) -> Void)? = nil) -> Data? {
        return Static.instance.load(key, failure: failure)
    }

    open class func load(_ key: String, failure: ((NSError) -> Void)? = nil) -> NSDictionary? {
        return Static.instance.load(key, failure: failure)
    }

    open class func load(_ key: String, failure: ((NSError) -> Void)? = nil) -> String? {
        return Static.instance.load(key, failure: failure)
    }

    open class func load<T>(_ key: String, success: (NSDictionary) -> T, failure: ((NSError) -> Void)?) -> T? {
        return Static.instance.load(key, success: success, failure: failure)
    }

    open class func load<T>(_ key: String, success: (NSDictionary) -> T) -> T? {
        return Static.instance.load(key, success: success, failure: nil)
    }

    open class func delete(_ key: String, failure: ((NSError) -> Void)? = nil) -> Bool {
        return Static.instance.delete(key, failure: failure)
    }

    open class func clear(_ failure: ((NSError) -> Void)? = nil) -> Bool {
        return Static.instance.clear(failure)
    }

    open class func printError(_ printError: Bool) {
        Static.printError = printError
    }

    // MARK: Debug Methods

    open class func defaultAccessGroup() -> String {
        let query: [String: AnyObject] = [
            kSecClass            as String : kSecClassGenericPassword,
            kSecAttrAccount      as String : "pw.aska.KeyClip.application-identifier-check" as AnyObject,
            kSecReturnAttributes as String : kCFBooleanTrue ]

        var result: AnyObject?
        var status = withUnsafeMutablePointer(to: &result) { SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0)) }

        if status == errSecItemNotFound {
            status = withUnsafeMutablePointer(to: &result) { SecItemAdd(query as CFDictionary, UnsafeMutablePointer($0)) }
        }

        if status == errSecSuccess {
            if let dictionary = result as? NSDictionary {
                if let accessGroup = dictionary[kSecAttrAccessGroup as NSString] as? NSString {
                    SecItemDelete(query as CFDictionary)
                    return accessGroup as String
                }
            }
        }

        // assertionFailure("failure get application-identifier")

        return ""
    }
}
