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

    init(_ dictionary: [AnyHashable: Any]) {
        self.name = dictionary[Constants.name] as! String
        self.password = dictionary[Constants.password] as! String
    }

    var dictionaryValue: [AnyHashable: String] {
        return [Constants.name: name, Constants.password: password]
    }
}

class KeyClipTests: XCTestCase {

    override func setUp() {
        super.setUp()
        
        try! KeyClip.clear()
    }

    override func tearDown() {
        try! KeyClip.clear()
        
        super.tearDown()
    }

    func testString() {
        let key1 = "testSaveLoadKey1"
        let key2 = "testSaveLoadKey2"
        let saveData = "data"

        do {
            XCTAssertTrue(try KeyClip.string(forKey: key1) == nil)
            XCTAssertTrue(try KeyClip.string(forKey: key2) == nil)

            try KeyClip.save(string: saveData, forKey: key1)

            XCTAssertFalse(try KeyClip.string(forKey: key1) == nil)
            XCTAssertTrue(try KeyClip.string(forKey: key2) == nil)

            let loadData = try KeyClip.string(forKey: key1)

            XCTAssertEqual(loadData, saveData)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testDictionary() {
        let key1 = "testSaveLoadKey1"
        let key2 = "testSaveLoadKey2"
        let saveAccount = Account([Account.Constants.name: "aska", Account.Constants.password: "********"])
        
        do {
            XCTAssertTrue(try KeyClip.string(forKey: key1) == nil)
            XCTAssertTrue(try KeyClip.string(forKey: key2) == nil)

            try KeyClip.save(dictionary: saveAccount.dictionaryValue, forKey: key1)

            XCTAssertFalse(try KeyClip.string(forKey: key1) == nil)
            XCTAssertTrue(try KeyClip.string(forKey: key2) == nil)

            let loadAccount = try KeyClip.load(key1) { (dictionary) -> Account in
                return Account(dictionary)
            }
            XCTAssertEqual(loadAccount!.name, saveAccount.name)

            let ring = KeyClip.Builder().build()
            let loadAccount2 = try ring.load(key1) { (dictionary) -> Account in
                return Account(dictionary)
            }
            XCTAssertEqual(loadAccount2!.name, saveAccount.name)

            let success = { (dictionary) -> Account in
                return Account(dictionary)
            }
            let loadAccount3 = try ring.load(key1, success: success)
            XCTAssertEqual(loadAccount3!.name, saveAccount.name)

            try KeyClip.save(string: "dummy", forKey: key1)
            
            do {
                let _ = try KeyClip.dictionary(forKey: key1)
                
                XCTFail("JSON parsing should throw error")
            } catch {
                // Do nothing
            }
        } catch {
            XCTFail("\(error)")
        }
    }

    func testDelete() {
        let key1 = "testDeleteKey1"
        let key2 = "testDeleteKey2"
        let saveData = "testDeleteData"
        
        do {
            try KeyClip.save(string: saveData, forKey: key1)
            try KeyClip.save(string: saveData, forKey: key2)

            XCTAssertFalse(try KeyClip.string(forKey: key1) == nil)
            XCTAssertFalse(try KeyClip.string(forKey: key2) == nil)

            XCTAssertTrue(try KeyClip.delete(key1))

            XCTAssertTrue(try KeyClip.string(forKey: key1) == nil)
            XCTAssertFalse(try KeyClip.string(forKey: key2) == nil)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testExists() {
        let key1 = "testDeleteKey1"
        let key2 = "testDeleteKey2"
        let saveData = "testDeleteData"
        
        do {
            try KeyClip.save(string: saveData, forKey: key1)
            try KeyClip.save(string: saveData, forKey: key2)

            XCTAssertTrue(try KeyClip.exists(key1))
            XCTAssertTrue(try KeyClip.exists(key2))

            XCTAssertTrue(try KeyClip.delete(key1))

            XCTAssertFalse(try KeyClip.exists(key1))
            XCTAssertTrue(try KeyClip.exists(key2))
        } catch {
            XCTFail("\(error)")
        }
    }

    func testClear() {
        let key = "testClearKey"
        let saveData = "testClearData"
        
        do {
            try KeyClip.save(string: saveData, forKey: key)
            
            XCTAssertFalse(try KeyClip.string(forKey: key) == nil)

            try KeyClip.clear()
            
            XCTAssertTrue(try KeyClip.string(forKey: key) == nil)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testService() {
        let key = "testSetServiceKey"
        let val1 = "testSetServiceVal1"
        let val2 = "testSetServiceVal2"

        let ring1 = KeyClip.Builder().service("Service1").build()
        let ring2 = KeyClip.Builder().service("Service2").build()

        do {
            try ring1.save(string: val1, forKey: key)
            try ring2.save(string: val2, forKey: key)

            XCTAssertTrue(try ring1.string(forKey: key) == val1)
            XCTAssertTrue(try ring2.string(forKey: key) == val2)
        } catch {
            XCTFail("\(error)")
        }

        XCTAssertEqual(ring1.service, "Service1")
        XCTAssertEqual(ring2.service, "Service2")
    }

    func testAccessible() {
        let key = "testSetServiceKey"
        let val = "testSetServiceVal"

        let ring = KeyClip.Builder().accessible(kSecAttrAccessibleAfterFirstUnlock as String).build()
        
        do {
            try ring.save(string: val, forKey: key)

            XCTAssertTrue(try ring.string(forKey: key) == val)
        } catch {
            XCTFail("\(error)")
        }

        XCTAssertEqual(ring.accessible, kSecAttrAccessibleAfterFirstUnlock as String)

        let foreground = KeyClip.Builder().accessible(kSecAttrAccessibleWhenUnlocked as String).build()
        let always = KeyClip.Builder().accessible(kSecAttrAccessibleAlways as String).build()

        XCTAssertEqual(foreground.accessible, kSecAttrAccessibleWhenUnlocked as String)
        XCTAssertEqual(always.accessible, kSecAttrAccessibleAlways as String)
    }

    func testAccessGroup() {
        #if os(iOS)
            let key = "testSetServiceKey"
            let val1 = "testSetServiceVal1"

            // kSecAttrAccessGroup is always "com.apple.token" on iOS 9 simulator's keychain
            let defaultAccessGroup = KeyClip.defaultAccessGroup()
            let ring1 = KeyClip.Builder().accessGroup(defaultAccessGroup).build()

            do {
                try ring1.save(string: val1, forKey: key)

                XCTAssertTrue(try ring1.exists(key))
                XCTAssertTrue(try ring1.string(forKey: key) == val1)
            } catch {
                XCTFail("\(error)")
            }

            XCTAssertEqual(ring1.accessGroup!, defaultAccessGroup)
        #endif
    }

    func testDefaultAccessGroup() {
        #if os(iOS)
            // XCTAssertEqual(KeyClip.defaultAccessGroup(), "ERYSSE5R77.pw.aska.TestApp-iOS")
        #endif
    }

    func testAccessGroupError() {
        #if os(iOS)
            let ring = KeyClip.Builder()
                .accessGroup("test.dummy")
                .build()
        
            do {
                try ring.save(string: "bar", forKey: "foo")
            } catch KeyClip.KeyClipError.unhandledError(let status) {
                XCTAssertTrue(status == -34018)
            } catch {
                XCTFail("\(error)")
            }
        #endif
    }
}
