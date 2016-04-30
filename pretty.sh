#!/bin/bash

# Q. Why do not you use the xctool?
# A. Because not suitable to test the Keychain.
# See: iOS keychain cannot be accessed in unit tests https://github.com/facebook/xctool/issues/454

xcodebuild "$@" | xcpretty -c && exit ${PIPESTATUS[0]}
