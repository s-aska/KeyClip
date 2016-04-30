XCODE_SCHEME_IOS = KeyClip iOS
XCODE_SDK_IOS = iphonesimulator

XCODE_SCHEME_MAC = KeyClip Mac
XCODE_SDK_MAC = macosx

XCTOOL_ARGS = -project KeyClip.xcodeproj -configuration Release build test -parallelize

test:
	xctool -scheme "$(XCODE_SCHEME_IOS)" -sdk "$(XCODE_SDK_IOS)" $(XCTOOL_ARGS)
	xctool -scheme "$(XCODE_SCHEME_MAC)" -sdk "$(XCODE_SDK_MAC)" $(XCTOOL_ARGS)
