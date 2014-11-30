# KeyClip [![Build Status](https://travis-ci.org/s-aska/KeyClip.svg)](https://travis-ci.org/s-aska/KeyClip)

KeyClip is yet another Keychain library written in Swift.

## Features

- [x] Comprehensive Unit Test Coverage
- [x] Carthage support

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
KeyClip.save("access_token", data: data) // -> Bool

KeyClip.load("access_token") // -> NSData?

KeyClip.delete("access_token") // Remove the data

KeyClip.clear() // Remove all the data
```

### Why NSData?

And if you want to save only the password, there is a case in which you want to save the account information.

```swift
// Save String
let data = "********".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!

// Save JSON
let data = NSJSONSerialization.dataWithJSONObject(["access_token": "********"], options: nil, error: nil)!
```

### Usuful

```swift
let key = "account"

// save
func save(account: NSDictionary) -> Bool {
    let data = NSJSONSerialization.dataWithJSONObject(account, options: nil, error: nil)!
    return KeyClip.save(key, data: data)
}

// load
func load() -> NSDictionary? {
    if let data = KeyClip.load(key) {
        if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) {
            return json as? NSDictionary
        }
    }
    return nil
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
