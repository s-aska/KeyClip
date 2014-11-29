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
    
    func testSaveLoad() {
        let key1 = "testSaveLoadKey1"
        let key2 = "testSaveLoadKey2"
        let saveData = "data".dataValue
        
        XCTAssertTrue(KeyClip.load(key1) == nil)
        XCTAssertTrue(KeyClip.load(key2) == nil)
        
        XCTAssertTrue(KeyClip.save(key1, data: saveData))
        
        XCTAssertTrue(KeyClip.load(key1) != nil)
        XCTAssertTrue(KeyClip.load(key2) == nil)
        
        let loadData = KeyClip.load(key1)!
        
        XCTAssertEqual(loadData.stringValue, saveData.stringValue)
    }
    
    
    func testDelete() {
        let key1 = "testDeleteKey1"
        let key2 = "testDeleteKey2"
        let saveData = "testDeleteData".dataValue
        
        XCTAssertTrue(KeyClip.save(key1, data: saveData))
        XCTAssertTrue(KeyClip.save(key2, data: saveData))
        
        XCTAssertTrue(KeyClip.load(key1) != nil)
        XCTAssertTrue(KeyClip.load(key2) != nil)
        
        XCTAssertTrue(KeyClip.delete(key1))
        
        XCTAssertTrue(KeyClip.load(key1) == nil)
        XCTAssertTrue(KeyClip.load(key2) != nil)
    }
    
    func testClear() {
        let key = "testClearKey"
        let data = "testClearData".dataValue
        
        KeyClip.save(key, data: data)
        XCTAssertTrue(KeyClip.load(key) != nil)
        
        KeyClip.clear()
        XCTAssertTrue(KeyClip.load(key) == nil)
    }
    
    func testReadmeCode() {
        save(["name": "aska"])
        if let dic = load() {
            XCTAssertEqual(dic["name"] as String, "aska")
        }
    }
    
}

// save
func save(account: NSDictionary) -> Bool {
    let data = NSJSONSerialization.dataWithJSONObject(account, options: nil, error: nil)!
    return KeyClip.save("testKey", data: data)
}

// load
func load() -> NSDictionary? {
    if let data = KeyClip.load("testKey") {
        if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) {
            return json as? NSDictionary
        }
    }
    return nil
}

extension String {
    public var dataValue: NSData {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    }
}

extension NSData {
    public var stringValue: String {
        return NSString(data: self, encoding: NSUTF8StringEncoding)!
    }
}
