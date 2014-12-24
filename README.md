# KeyClip [![Build Status](https://travis-ci.org/s-aska/KeyClip.svg)](https://travis-ci.org/s-aska/KeyClip)

KeyClip is yet another Keychain library written in Swift.

### !!! warning !!!

Swift compiler can't read correctly the data of Keychain when Optimization Level is `Fastest`.

So, [Optimization Level for the Carthage](https://github.com/s-aska/KeyClip/blob/master/KeyClip.xcodeproj/project.pbxproj#L351) is `None`.

However, Optimization Level for the your application usable the `Fastest`.

See http://stackoverflow.com/questions/26355630/swift-keychain-and-provisioning-profiles

## Features

- [x] Comprehensive Unit Test Coverage
- [x] Carthage support
- [x] NSDictionary / String support
- [ ] The Release Optimization level to `Fastest [-O]` when resolved Swift compiler bugs.

## Requirements

- iOS 8+
- Xcode 6.1


## Installation

Create a Cartfile that lists the frameworks you’d like to use in your project.

```bash
echo 'github "s-aska/KeyClip"' >> Cartfile
```

Run `carthage update`

```bash
carthage update
```

On your application targets’ “General” settings tab, in the “Embedded Binaries” section, drag and drop each framework you want to use from the Carthage.build folder on disk.


## Usage

### Minimum

```swift
KeyClip.save("access_token", string: "********") // -> Bool

let token = KeyClip.load("access_token") as String?

KeyClip.delete("access_token") // Remove the data

KeyClip.clear() // Remove all the data
```

### NSDictionary (compatible to NSJSONSerialization)

```swift
KeyClip.save("account", dictionary: ["name": "aska", "token": "******"]) // -> Bool

let dictionary = KeyClip.load("access_token") as NSDictionary?
```

### NSData

```swift
KeyClip.save("account", data: NSData()) // -> Bool

let data = KeyClip.load("access_token") as NSData?
```

### Usuful

```swift
let key = "account"

func save(account: Account) -> Bool {
    return KeyClip.save(key, account.dictionaryValue)
}

func load() -> Account? {
    if let dictionary = KeyClip.load(key) as NSDictionary? {
        return Account(dictionary)
    } else {
        return nil
    }
}

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
```

### Specify the kSecAttrService

```swift
KeyClip.setService("com...") // default is NSBundle.mainBundle().bundleIdentifier
```

### Specify the kSecAttrAccessible

```swift
KeyClip.setAccessible(kSecAttrAccessibleAfterFirstUnlock) // default is kSecAttrAccessibleWhenUnlocked
```

### Specify the kSecAttrAccessGroup

:warning: Note that the iOS Simulator's keychain implementation does not support kSecAttrAccessGroup.

:warning: There are many constraints to kSecAttrAccessGroup. https://developer.apple.com/library/mac/documentation/Security/Reference/keychainservices/index.html

```swift
KeyClip.setGroup("com...share") // default is nil
```

### Multi Instance

```swift
let background = KeyClip.Builder()
                .service("BackgroundService")
                .accessible(kSecAttrAccessibleAfterFirstUnlock)
                .build()

let foreground = KeyClip.Builder()
                .service("ForegroundService")
                .accessible(kSecAttrAccessibleWhenUnlocked)
                .build()

let shared = KeyClip.Builder()
                .group("com...share")
                .service("ShearedService")
                .build()
```


## License

KeyClip is released under the MIT license. See LICENSE for details.
