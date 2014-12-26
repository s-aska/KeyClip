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

### NSDictionary

Must be compatible to NSJSONSerialization.

Valid JSON elements are Dictionary, Array, String, Number, Boolean and null.

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
func save(account: Account) -> Bool {
    return KeyClip.save("account", account.dictionaryValue)
}

func load() -> Account? {
    if let dictionary = KeyClip.load("account") as NSDictionary? {
        return Account(dictionary)
    } else {
        return nil
    }
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

### Error Handling

#### Return value

Usually this is enough.

```swift
let success = KeyClip.save("hoge", string: "bar")
if !success {
    // Show Alert "failed to save to KeyChain"
}
```

#### Temporary specifies

handleError is possible to change the error message by OSStatus.

```swift
KeyClip
    .handleError { error in
        let status = error.code // OSStatus
        // Show Alert "failed to save to KeyChain code:\(error.code)"
    }
    .save("hoge", string: "bar")
```

#### Instances settings

Always enable. (eg. Send crash report.)

Instances's settings and temporary specifies can be combined.

```swift
KeyClip.Builder()

    // Debug print
    .printError(true)

    // Error Handler
    .handleError({ error in
        let status = error.code // OSStatus
    })

    // apply to default settings
    .buildDefault()
```

### Single Instance Settings

:warning: iOS Simulator's keychain implementation does not support kSecAttrAccessGroup. (always "test")

:warning: kSecAttrAccessGroup must match the App Identifier prefix. https://developer.apple.com/library/mac/documentation/Security/Reference/keychainservices/index.html

```swift
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
    .handleError({ error in
        let status = error.code // OSStatus
    })

    // update for default instance
    .buildDefault()
```

### Multi Instance Settings

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
                .printError(true)
                .service("ShearedService")
                .accessGroup("XXXX23F3DC53.com.example.share")
                .build()
```

### How to check the App Identifier (for Debug)

:warning: iOS Simulator's keychain implementation does not support kSecAttrAccessGroup. (always "test")

```swift
println(KeyClip.defaultAccessGroup()) // -> String (eg. XXXX23F3DC53.*)
```


## License

KeyClip is released under the MIT license. See LICENSE for details.
