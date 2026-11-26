PROJECT := FocusBar.xcodeproj
SCHEME := FocusBar
DERIVED_DATA := .build/DerivedData
DERIVED_DATA_RELEASE := .build/DerivedData-Release
ARCHIVE_PATH := .build/FocusBar.xcarchive
APP_PATH := $(DERIVED_DATA)/Build/Products/Debug/FocusBar.app
RELEASE_APP_PATH := $(DERIVED_DATA_RELEASE)/Build/Products/Release/FocusBar.app
EXPORT_PATH := .build/export

.PHONY: dev build release archive export-appstore verify-signature test ui-test stop clean

dev: build
	-pkill -x FocusBar 2>/dev/null || true
	open $(APP_PATH)

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED_DATA) build

release:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -derivedDataPath $(DERIVED_DATA_RELEASE) build
	@echo "Verifying code signature and hardened runtime:"
	codesign -dvvv $(RELEASE_APP_PATH)
	@echo "Creating signed distribution zip..."
	ditto -c -k --sequesterRsrc --keepParent $(RELEASE_APP_PATH) .build/FocusBar.app.zip
	@echo "Built release app at $(RELEASE_APP_PATH) and .build/FocusBar.app.zip"

archive:
	rm -rf $(ARCHIVE_PATH)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -archivePath $(ARCHIVE_PATH) archive

export-appstore: archive
	rm -rf $(EXPORT_PATH)
	xcodebuild -exportArchive -archivePath $(ARCHIVE_PATH) -exportOptionsPlist ExportOptions-AppStore.plist -exportPath $(EXPORT_PATH) -allowProvisioningUpdates

verify-signature:
	@if [ -d "$(RELEASE_APP_PATH)" ]; then \
		echo "=== Release App Code Signature ==="; \
		codesign -dvvv --deep $(RELEASE_APP_PATH); \
		echo "\n=== Entitlements ==="; \
		codesign -d --entitlements - $(RELEASE_APP_PATH); \
	else \
		echo "Release app not found at $(RELEASE_APP_PATH). Run 'make release' first."; \
	fi

test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=macOS' -derivedDataPath $(DERIVED_DATA) -only-testing:FocusBarTests

ui-test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=macOS' -derivedDataPath $(DERIVED_DATA) -only-testing:FocusBarUITests

stop:
	-pkill -x FocusBar 2>/dev/null || true

clean:
	rm -rf .build
