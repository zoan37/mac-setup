# Stay Awake: a menu-bar mug that keeps this Mac awake (like `caffeinate -dims`).
#
#   make            build build/StayAwake.app
#   make install    copy it to /Applications and launch it
#   make uninstall  remove the login item, the app, and its saved state
#
# Signing is ad-hoc by default. To sign with a real identity:
#   make install IDENTITY="Apple Development: Your Name (TEAMID)"

APP       := build/StayAwake.app
BUNDLE_ID := com.zoan.StayAwake
IDENTITY  ?= -
DEST      ?= /Applications/StayAwake.app
SOURCES   := $(wildcard Sources/StayAwake/*.swift)

.PHONY: build install uninstall clean

build:
	rm -rf $(APP) build/AppIcon.iconset
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	swiftc -O -target $(shell uname -m)-apple-macos14.0 $(SOURCES) -o $(APP)/Contents/MacOS/StayAwake
	cp Resources/Info.plist $(APP)/Contents/Info.plist
	swift scripts/make-icon.swift build/AppIcon.iconset
	iconutil -c icns build/AppIcon.iconset -o $(APP)/Contents/Resources/AppIcon.icns
	codesign --force --sign "$(IDENTITY)" --identifier $(BUNDLE_ID) $(APP)

install: build
	-pkill -x StayAwake
	while pgrep -x StayAwake >/dev/null; do sleep 0.2; done
	rm -rf "$(DEST)"
	ditto $(APP) "$(DEST)"
	open "$(DEST)"

uninstall:
	-"$(DEST)/Contents/MacOS/StayAwake" --login-off
	-pkill -x StayAwake
	rm -rf "$(DEST)"
	-defaults delete $(BUNDLE_ID)

clean:
	rm -rf build
