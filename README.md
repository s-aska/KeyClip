# KeyClip [![Build Status](https://travis-ci.org/s-aska/KeyClip.svg)](https://travis-ci.org/s-aska/KeyClip)

KeyClip is yet another Keychain library written in Swift.


## Features

- [x] Comprehensive Unit Test Coverage
- [x] Carthage support
- [x] NSDictionary / String support


## Requirements

- iOS 8+
- Xcode 6.1


## Installation

Create a Cartfile that lists the frameworks you’d like to use in your project.

    $ echo 'github "s-aska/KeyClip"' >> Cartfile

Run `carthage update`

    $ carthage update

On your application targets’ “General” settings tab, in the “Embedded Binaries” section, drag and drop each framework you want to use from the Carthage.build folder on disk.


## Usage

### Minimum

```swift
KeyClip.save("access_token", string: "********") // -> Bool

let token: String? = KeyClip.load("access_token")

KeyClip.delete("access_token") // Remove the data

KeyClip.clear() // Remove all the data
```

### NSDictionary

```swift
KeyClip.save("account", dictionary: ["name": "aska", "password": "********"]) // -> Bool

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
KeyClip.setService("YourService") // default is NSBundle.mainBundle().bundleIdentifier
```


## Todo

The Release Optimization level to `-O` when resolved Swift compiler bugs.

http://stackoverflow.com/questions/26355630/swift-keychain-and-provisioning-profiles


## License

KeyClip is released under the MIT license. See LICENSE for details.
