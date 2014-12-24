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
        KeyClip.clear()
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
    
    func testSetService() {
        let key = "testSetServiceKey"
        let val1 = "testSetServiceVal1"
        let val2 = "testSetServiceVal2"
        
        let ring1 = KeyClip.Builder().service("Service1").build()
        let ring2 = KeyClip.Builder().service("Service2").build()
        
        ring1.save(key, string: val1)
        ring2.save(key, string: val2)
        
        XCTAssertTrue(ring1.load(key) == val1)
        XCTAssertTrue(ring2.load(key) == val2)
    }
    
    func testSetAccessible() {
        let key = "testSetServiceKey"
        let val = "testSetServiceVal"
        
        KeyClip.setAccessible(kSecAttrAccessibleAfterFirstUnlock)
        
        let ring = KeyClip.Builder().accessible(kSecAttrAccessibleAfterFirstUnlock).build()
        
        ring.save(key, string: val)
        
        XCTAssertTrue(ring.load(key) == val)
    }
    
    func testAccessGroup() {
        let key = "testSetServiceKey"
        let val1 = "testSetServiceVal1"
        let val2 = "testSetServiceVal2"
        let val3 = "testSetServiceVal3"
        
        // kSecAttrAccessGroup is always "test" on simulator's keychain
        let ring1 = KeyClip.Builder().accessGroup("test").build()
        let ring2 = KeyClip.Builder().accessGroup("test").service("Service1").build()
        let ring3 = KeyClip.Builder().accessGroup("test").accessible(kSecAttrAccessibleAfterFirstUnlock).build()
        let ring4 = KeyClip.Builder()
            .accessGroup("test.dummy") // always failure
            .service("Service1")
            .accessible(kSecAttrAccessibleAfterFirstUnlock)
            .build()
        
        ring1.save(key, string: val1)
        ring2.save(key, string: val2)
        ring3.save(key, string: val3)
        ring4.save(key, string: val3)
        
        XCTAssertTrue(ring1.load(key) == val1)
        XCTAssertTrue(ring2.load(key) == val2)
        XCTAssertTrue(ring3.load(key) == val3)
        XCTAssertTrue((ring4.load(key) as String?) == nil)
    }
}
