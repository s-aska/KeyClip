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
        self.name = dictionary[Constants.name] as! String
        self.password = dictionary[Constants.password] as! String
    }

    var dictionaryValue: [String: String] {
        return [Constants.name: name, Constants.password: password]
    }
}

class KeyClipTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let _ = KeyClip.clear()
        KeyClip.printError(true)
    }

    override func tearDown() {
        let _ = KeyClip.clear()
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

        let ring = KeyClip.Builder().build()
        let loadAccount2 = ring.load(key1) { (dictionary) -> Account in
            return Account(dictionary)
        }
        XCTAssertEqual(loadAccount2!.name, saveAccount.name)

        let success = { (dictionary) -> Account in
            return Account(dictionary)
        }
        let loadAccount3 = ring.load(key1, success: success)
        XCTAssertEqual(loadAccount3!.name, saveAccount.name)

        XCTAssertTrue(KeyClip.save(key1, string: "dummy"))
        var hasError = false
        let data: NSDictionary? = KeyClip.load(key1, failure: { (error: NSError) in
            hasError = true
        })

        XCTAssertEqual(data, nil)
        XCTAssertTrue(hasError)
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

        XCTAssertTrue(KeyClip.save(key, string: saveData))
        XCTAssertTrue((KeyClip.load(key) as String?) != nil)

        XCTAssertTrue(KeyClip.clear())
        XCTAssertTrue((KeyClip.load(key) as String?) == nil)
    }

    func testService() {
        let key = "testSetServiceKey"
        let val1 = "testSetServiceVal1"
        let val2 = "testSetServiceVal2"

        let ring1 = KeyClip.Builder().service("Service1").build()
        let ring2 = KeyClip.Builder().service("Service2").build()

        XCTAssertTrue(ring1.save(key, string: val1))
        XCTAssertTrue(ring2.save(key, string: val2))

        XCTAssertTrue(ring1.load(key) == val1)
        XCTAssertTrue(ring2.load(key) == val2)

        XCTAssertEqual(ring1.service, "Service1")
        XCTAssertEqual(ring2.service, "Service2")
    }

    func testAccessible() {
        let key = "testSetServiceKey"
        let val = "testSetServiceVal"

        let ring = KeyClip.Builder().accessible(kSecAttrAccessibleAfterFirstUnlock as String).build()

        XCTAssertTrue(ring.save(key, string: val))

        XCTAssertTrue(ring.load(key) == val)

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
            let val2 = "testSetServiceVal2"

            // kSecAttrAccessGroup is always "com.apple.token" on iOS 10 simulator's keychain
            let defaultAccessGroup = KeyClip.defaultAccessGroup()
            let ring1 = KeyClip.Builder().accessGroup(defaultAccessGroup).build()
            let ring2 = KeyClip.Builder()
                .accessGroup("test.dummy") // always failure
            .build()

            XCTAssertTrue(ring1.save(key, string: val1))

            XCTAssertFalse(ring2.save(key, string: val2))

            XCTAssertTrue(ring1.exists(key))

            XCTAssertTrue(ring1.load(key) == val1)

            XCTAssertNil(ring2.load(key) as String?)

            XCTAssertEqual(ring1.accessGroup!, defaultAccessGroup)
            XCTAssertEqual(ring2.accessGroup!, "test.dummy")
        #endif
    }

    func testDefaultAccessGroup() {
        #if os(iOS)
            XCTAssertEqual(KeyClip.defaultAccessGroup(), "com.apple.token")
        #endif
    }

    func testAccessGroupError() {
        #if os(iOS)
            var errorCount = 0
            let ring = KeyClip.Builder()
                .accessGroup("test.dummy")
                .build()

            let ret = ring.save("hoge", string: "bar") { error -> Void in
                errorCount += 1
                let status = error.code // OSStatus
                let defaultAccessGroup = KeyClip.defaultAccessGroup()
                NSLog("[KeyClip] Error status:\(status) App Identifier:\(defaultAccessGroup)")
            }
            XCTAssertFalse(ret)

            XCTAssertTrue(errorCount == 1)
        #endif
    }
}
