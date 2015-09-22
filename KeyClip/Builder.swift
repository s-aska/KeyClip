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
        var service: String = NSBundle.mainBundle().bundleIdentifier ?? "pw.aska.KeyClip"
        var accessible: String = kSecAttrAccessibleAfterFirstUnlock as String
        
        public init() {}
        
        public func accessGroup(accessGroup: String) -> Builder {
            self.accessGroup = accessGroup
            return self
        }
        
        public func service(service: String) -> Builder {
            self.service = service
            return self
        }
        
        public func accessible(accessible: String) -> Builder {
            self.accessible = accessible
            return self
        }
        
        public func build() -> Ring {
            return Ring(accessGroup: accessGroup, service: service, accessible: accessible)
        }
    }
}
