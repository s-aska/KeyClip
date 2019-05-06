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
    fileprivate static let shared = KeyClip.Builder().build()

    // MARK: Public Methods

    open class func exists(_ key: String) throws -> Bool {
        return try KeyClip.shared.exists(key)
    }

    open class func save(data: Data, forKey key: String) throws {
        return try KeyClip.shared.save(data: data, forKey: key)
    }

    open class func save(string: String, forKey key: String) throws {
        return try KeyClip.shared.save(string: string, forKey: key)
    }

    open class func save(dictionary: [AnyHashable: Any], forKey key: String) throws {
        return try KeyClip.shared.save(dictionary: dictionary, forKey: key)
    }

    open class func data(forKey key: String) throws -> Data? {
        return try KeyClip.shared.data(forKey: key)
    }

    open class func dictionary(forKey key: String) throws -> [AnyHashable: Any]? {
        return try KeyClip.shared.dictionary(forKey: key)
    }

    open class func string(forKey key: String) throws -> String? {
        return try KeyClip.shared.string(forKey:key)
    }

    open class func load<T>(_ key: String, success: ([AnyHashable: Any]) -> T) throws -> T? {
        return try KeyClip.shared.load(key, success: success)
    }

    @discardableResult
    open class func delete(_ key: String) throws -> Bool {
        return try KeyClip.shared.delete(key)
    }

    @discardableResult
    open class func clear() throws -> Bool {
        return try KeyClip.shared.clear()
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
