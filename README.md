# KeyClip

[![Build Status](https://www.bitrise.io/app/8ab98cb35d63d2a8.svg?token=bPKUkQrsCZT8SlQaflgdOA&branch=master)](https://www.bitrise.io/app/8ab98cb35d63d2a8)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![](https://img.shields.io/badge/Xcode-7.0%2B-brightgreen.svg?style=flat)]()
[![](https://img.shields.io/badge/iOS-8.0%2B-brightgreen.svg?style=flat)]()
[![](https://img.shields.io/badge/OS%20X-10.10%2B-brightgreen.svg?style=flat)]()

KeyClip is yet another Keychain library written in Swift.

## Features

- [x] Multi Types ( String / NSDictionary / NSData )
- [x] Error Handling
- [x] Settings ( kSecAttrAccessGroup / kSecAttrService / kSecAttrAccessible )
- [x] [Works fine with release ( Fastest \[-O\] ) build.](http://stackoverflow.com/questions/24145838/querying-ios-keychain-using-swift/27721328?stw=2#27721328)


## Usage

### String

```swift
KeyClip.save("access_token", string: "********") // -> Bool

let token = KeyClip.load("access_token") as String?

KeyClip.delete("access_token") // Remove the data

KeyClip.clear() // Remove all the data

KeyClip.exists("access_token") // -> Bool
```

### NSDictionary

Must be compatible to NSJSONSerialization.

Valid JSON elements are Dictionary, Array, String, Number, Boolean and null.

```swift
KeyClip.save("account", dictionary: ["name": "aska", "token": "******"]) // -> Bool

let dictionary = KeyClip.load("account") as NSDictionary?
```

### NSData

```swift
KeyClip.save("data", data: NSData()) // -> Bool

let data = KeyClip.load("data") as NSData?
```

### Your Class

```swift
KeyClip.save("account", dictionary: account.dictionaryValue)

let account = KeyClip.load("account") { (dictionary) -> Account in
    return Account(dictionary)
}

class Account {
    let name: String
    let password: String

    init(_ dictionary: NSDictionary) {
        self.name = dictionary["name"] as String
        self.password = dictionary["password"] as String
    }

    var dictionaryValue: [String: String] {
        return ["name": name, "password": password]
    }
}
```

## Error Handling

### Return value

```swift
let success = KeyClip.save("password", string: "********")
if !success {
    // Show Alert "Saving password to keychain failed"
}
```

### Clojure

```swift
KeyClip.save("password", string: "********") { error in
    let status = error.code // OSStatus
    // Show Alert "Saving failed \(error.localizedDescription)(\(error.code))"
}
```

### Debug print

```swift
KeyClip.printError(true)
```


## Settings

```swift
let clip = KeyClip.Builder()

    // kSecAttrService
    .service(NSBundle.mainBundle().bundleIdentifier) // default

    // kSecAttrAccessible
    .accessible(kSecAttrAccessibleAfterFirstUnlock) // default

    // kSecAttrAccessGroup
    .accessGroup("XXXX23F3DC53.com.example.share") // default is nil

    .build()
```

### Note to accessGroup

:warning: iOS Simulator's keychain implementation does not support kSecAttrAccessGroup. (always "test")

:warning: kSecAttrAccessGroup must match the App Identifier prefix. https://developer.apple.com/library/mac/documentation/Security/Reference/keychainservices/index.html

#### How to check the App Identifier

Entitlement.plist's keychain-access-groups or App Identifier.

```swift
KeyClip.defaultAccessGroup() // -> String (eg. XXXX23F3DC53.*)
```


## Requirements

- iOS 8.0+ / Mac OS X 10.10+
- Xcode 7.0+


## Installation

#### Carthage

Add the following line to your [Cartfile](https://github.com/carthage/carthage)

```
github "s-aska/KeyClip"
```

#### CocoaPods

Add the following line to your [Podfile](https://guides.cocoapods.org/)

```
use_frameworks!
pod 'KeyClip'
```


## License

KeyClip is released under the MIT license. See LICENSE for details.
