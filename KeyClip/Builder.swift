//
//  Builder.swift
//  KeyClip
//
//  Created by Shinichiro Aska on 8/26/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

public extension KeyClip {
    public class Builder {

        var accessGroup: String?
        var service: String = Bundle.main.bundleIdentifier ?? "pw.aska.KeyClip"
        var accessible: String = kSecAttrAccessibleAfterFirstUnlock as String

        public init() {}

        open func accessGroup(_ accessGroup: String) -> Builder {
            self.accessGroup = accessGroup
            return self
        }

        open func service(_ service: String) -> Builder {
            self.service = service
            return self
        }

        open func accessible(_ accessible: String) -> Builder {
            self.accessible = accessible
            return self
        }

        open func build() -> Ring {
            return Ring(accessGroup: accessGroup, service: service, accessible: accessible)
        }
    }
}
