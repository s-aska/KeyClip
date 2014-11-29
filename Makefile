
default: test

build:
	xcodebuild -sdk iphonesimulator -target KeyClip build

test:
	#xcodebuild -sdk iphonesimulator -scheme KeyClipTests test
	xctool -sdk iphonesimulator -arch i386 -scheme KeyClipTests test

clean:
	xcodebuild -sdk iphonesimulator clean

.PHONY: build test clean default