PROJECT := FocusBar.xcodeproj
SCHEME := FocusBar
DERIVED_DATA := .build/DerivedData
APP_PATH := $(DERIVED_DATA)/Build/Products/Debug/FocusBar.app

.PHONY: dev build test ui-test stop clean

dev: build
	-pkill -x FocusBar 2>/dev/null || true
	open $(APP_PATH)

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED_DATA) build

test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=macOS' -derivedDataPath $(DERIVED_DATA) -only-testing:FocusBarTests

ui-test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=macOS' -derivedDataPath $(DERIVED_DATA) -only-testing:FocusBarUITests

stop:
	-pkill -x FocusBar 2>/dev/null || true

clean:
	rm -rf .build
