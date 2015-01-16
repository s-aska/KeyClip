//
//  KeyClipTests.swift
//  KeyClipTests
//
//  Created by Shinichiro Aska on 11/29/14.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import Foundation
import XCTest
import KeyClip

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

class KeyClipTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        KeyClip.clear()
        KeyClip.printError(true)
    }
    
    override func tearDown() {
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
        let key1 = "testSaveLoadKey1"
        let key2 = "testSaveLoadKey2"
        let saveAccount = Account([Account.Constants.name: "aska", Account.Constants.password: "********"])
        
        XCTAssertTrue((KeyClip.load(key1) as String?) == nil)
        XCTAssertTrue((KeyClip.load(key2) as String?) == nil)
        
        XCTAssertTrue(KeyClip.save(key1, dictionary: saveAccount.dictionaryValue))
        
        XCTAssertTrue((KeyClip.load(key1) as String?) != nil)
        XCTAssertTrue((KeyClip.load(key2) as String?) == nil)
        
        let loadAccount = KeyClip.load(key1) { (dictionary) -> Account in
            return Account(dictionary)
        }
        
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
    
    func testExists() {
        let key1 = "testDeleteKey1"
        let key2 = "testDeleteKey2"
        let saveData = "testDeleteData"
        
        XCTAssertTrue(KeyClip.save(key1, string: saveData))
        XCTAssertTrue(KeyClip.save(key2, string: saveData))
        
        XCTAssertTrue(KeyClip.exists(key1))
        XCTAssertTrue(KeyClip.exists(key2))
        
        XCTAssertTrue(KeyClip.delete(key1))
        
        XCTAssertTrue(!KeyClip.exists(key1))
        XCTAssertTrue(KeyClip.exists(key2))
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
        #if os(iOS)
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
        
        ring2.save(key, string: val2) { (error) -> Void in
            XCTAssertTrue(error.code == -25243) // errSecNoAccessForItem
            XCTAssertEqual(error.localizedDescription, "Ignore the access group if running on the iPhone simulator.")
        }
        
        XCTAssertTrue(ring1.exists(key))
        
        XCTAssertTrue(ring1.load(key) == val1)
        
        XCTAssertNil(ring2.load(key) as String?)
        
        XCTAssertEqual(ring1.accessGroup!, "test")
        XCTAssertEqual(ring2.accessGroup!, "test.dummy")
        #endif
    }
    
    func testDefaultAccessGroup() {
        #if os(iOS)
        XCTAssertTrue(KeyClip.defaultAccessGroup() == "test")
        #endif
    }
    
    func testAccessGroupError() {
        #if os(iOS)
        var errorCount = 0
        let ring = KeyClip.Builder()
            .accessGroup("test.dummy")
            .build()
        
        ring.save("hoge", string: "bar") { error -> Void in
            errorCount++
            XCTAssertEqual(error.code, -25243)
            let status = error.code // OSStatus
            let defaultAccessGroup = KeyClip.defaultAccessGroup()
            NSLog("[KeyClip] Error status:\(status) App Identifier:\(defaultAccessGroup)")
        }
        
        XCTAssertTrue(errorCount == 1)
        #endif
    }
}
