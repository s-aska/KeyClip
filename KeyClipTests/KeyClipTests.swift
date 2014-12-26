//
//  KeyClipTests.swift
//  KeyClipTests
//
//  Created by Shinichiro Aska on 11/29/14.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit
import XCTest
import KeyClip

class KeyClipTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        KeyClip.Builder().buildDefault()
        KeyClip.clear()
    }
    
    override func tearDown() {
        KeyClip.Builder().buildDefault()
        KeyClip.clear()
        super.tearDown()
    }
    
    func testString() {
        let key1 = "testSaveLoadKey1"
        let key2 = "testSaveLoadKey2"
        let saveData = "data"
        
        XCTAssertTrue((KeyClip.load(key1) as String?) == nil)
        XCTAssertTrue((KeyClip.load(key2) as String?) == nil)
        
        XCTAssertTrue(KeyClip.save(key1, string: saveData))
        
        XCTAssertTrue((KeyClip.load(key1) as String?) != nil)
        XCTAssertTrue((KeyClip.load(key2) as String?) == nil)
        
        let loadData = KeyClip.load(key1) ?? ""
        
        XCTAssertEqual(loadData, saveData)
    }
    
    func testDictionary() {
        
        class Account {
            
            struct Constants {
                static let name = "name"
                static let password = "password"
            }
            
            let name: String
            let password: String
            
            init(_ dictionary: NSDictionary) {
                self.name = dictionary[Constants.name] as String
                self.password = dictionary[Constants.password] as String
            }
            
            var dictionaryValue: [String: String] {
                return [Constants.name: name, Constants.password: password]
            }
        }
        
        let key1 = "testSaveLoadKey1"
        let key2 = "testSaveLoadKey2"
        let saveAccount = Account(["name": "aska", "password": "********"])
        
        XCTAssertTrue((KeyClip.load(key1) as String?) == nil)
        XCTAssertTrue((KeyClip.load(key2) as String?) == nil)
        
        XCTAssertTrue(KeyClip.save(key1, dictionary: saveAccount.dictionaryValue))
        
        XCTAssertTrue((KeyClip.load(key1) as String?) != nil)
        XCTAssertTrue((KeyClip.load(key2) as String?) == nil)
        
        let loadAccount: Account? = {
            if let dictionary = KeyClip.load(key1) as NSDictionary? {
                return Account(dictionary)
            } else {
                return nil
            }
            }()
        
        XCTAssertEqual(loadAccount!.name, saveAccount.name)
    }
    
    func testDelete() {
        let key1 = "testDeleteKey1"
        let key2 = "testDeleteKey2"
        let saveData = "testDeleteData"
        
        XCTAssertTrue(KeyClip.save(key1, string: saveData))
        XCTAssertTrue(KeyClip.save(key2, string: saveData))
        
        XCTAssertTrue((KeyClip.load(key1) as String?) != nil)
        XCTAssertTrue((KeyClip.load(key2) as String?) != nil)
        
        XCTAssertTrue(KeyClip.delete(key1))
        
        XCTAssertTrue((KeyClip.load(key1) as String?) == nil)
        XCTAssertTrue((KeyClip.load(key2) as String?) != nil)
    }
    
    func testClear() {
        let key = "testClearKey"
        let saveData = "testClearData"
        
        KeyClip.save(key, string: saveData)
        XCTAssertTrue((KeyClip.load(key) as String?) != nil)
        
        KeyClip.clear()
        XCTAssertTrue((KeyClip.load(key) as String?) == nil)
    }
    
    func testService() {
        let key = "testSetServiceKey"
        let val1 = "testSetServiceVal1"
        let val2 = "testSetServiceVal2"
        
        let ring1 = KeyClip.Builder().service("Service1").build()
        let ring2 = KeyClip.Builder().service("Service2").build()
        
        ring1.save(key, string: val1)
        ring2.save(key, string: val2)
        
        XCTAssertTrue(ring1.load(key) == val1)
        XCTAssertTrue(ring2.load(key) == val2)
        
        XCTAssertEqual(ring1.service, "Service1")
        XCTAssertEqual(ring2.service, "Service2")
    }
    
    func testAccessible() {
        let key = "testSetServiceKey"
        let val = "testSetServiceVal"
        
        KeyClip.Builder().accessible(kSecAttrAccessibleAfterFirstUnlock).buildDefault()
        
        let ring = KeyClip.Builder().accessible(kSecAttrAccessibleAfterFirstUnlock).build()
        
        ring.save(key, string: val)
        
        XCTAssertTrue(ring.load(key) == val)
        
        XCTAssertEqual(ring.accessible, kSecAttrAccessibleAfterFirstUnlock)
        
        let foreground = KeyClip.Builder().accessible(kSecAttrAccessibleWhenUnlocked).build()
        let always = KeyClip.Builder().accessible(kSecAttrAccessibleAlways).build()
        
        XCTAssertEqual(foreground.accessible, kSecAttrAccessibleWhenUnlocked)
        XCTAssertEqual(always.accessible, kSecAttrAccessibleAlways)
    }
    
    func testAccessGroup() {
        let key = "testSetServiceKey"
        let val1 = "testSetServiceVal1"
        let val2 = "testSetServiceVal2"
        let val3 = "testSetServiceVal3"
        
        // kSecAttrAccessGroup is always "test" on simulator's keychain
        let ring1 = KeyClip.Builder().accessGroup("test").build()
        let ring2 = KeyClip.Builder()
            .accessGroup("test.dummy") // always failure
            .build()
        
        ring1.save(key, string: val1)
        ring2
            .handleError { error in
                XCTAssertTrue(error.code == -25243) // errSecNoAccessForItem
        }
            .save(key, string: val1)
        
        XCTAssertTrue(ring1.load(key) == val1)
        XCTAssertNil(ring2.load(key) as String?)
        
        XCTAssertEqual(ring1.accessGroup!, "test")
        XCTAssertEqual(ring2.accessGroup!, "test.dummy")
    }
    
    func testDefaultAccessGroup() {
        XCTAssertTrue(KeyClip.defaultAccessGroup() == "test")
    }
    
    func testError() {
        var errorCount = 0
        let ring = KeyClip.Builder()
            .printError(true)
            .handleError({ error in
                errorCount++
                XCTAssertEqual(error.code, -25243)
                let status = error.code // OSStatus
                let defaultAccessGroup = KeyClip.defaultAccessGroup()
                NSLog("[KeyClip] Error status:\(status) App Identifier:\(defaultAccessGroup)")
            })
            .accessGroup("test.dummy")
            .build()

        ring.save("hoge", string: "bar")
        
        KeyClip.Builder().accessGroup("test.dummy").buildDefault()
        
        KeyClip
            .handleError { error in
                errorCount++
                XCTAssertEqual(error.code, -25243)
            }
            .save("hoge", string: "bar")
        
        XCTAssertTrue(errorCount == 2)
    }
    
    func testUsage() {
        KeyClip.save("account_data", data: NSData()) // Bool
        KeyClip.save("access_token", string: "********") // Bool
        KeyClip.save("account", dictionary: ["name": "Aska"]) // Bool
        
        let data: NSData? = KeyClip.load("account_data")
        let access_token: String? = KeyClip.load("access_token")
        let account: NSDictionary? = KeyClip.load("account")
        
        let ring = KeyClip.Builder()
            .accessGroup("test") // kSecAttrAccessGroup
            .service("Service1") // kSecAttrService
            .accessible(kSecAttrAccessibleAfterFirstUnlock) // kSecAttrAccessible
            .build()
        
        KeyClip.Builder()
            
            // kSecAttrAccessGroup, default is nil
            .accessGroup("XXXX23F3DC53.com.example")
            
            // kSecAttrService, default is NSBundle.mainBundle().bundleIdentifier
            .service("Service")
            
            // kSecAttrAccessible, default is kSecAttrAccessibleWhenUnlocked
            .accessible(kSecAttrAccessibleWhenUnlocked)
            
            // Casual Debug
            .printError(true)
            
            // Error Handler
            .handleError({ (error: NSError) in
                let status: OSStatus = Int32(error.code)
            })
            
            // update for default instance
            .buildDefault()
    }
}
