BUILD := build
SAVER := $(BUILD)/Havbunn.saver
CONTENTS := $(SAVER)/Contents
ENGINE := $(wildcard Sources/Engine/*.swift)
TARGET := 12.0
SDK := $(shell xcrun --sdk macosx --show-sdk-path)
SWIFTC := xcrun swiftc -sdk $(SDK) -swift-version 5 -O -whole-module-optimization
# Ad-hoc by default. Set SIGN_IDENTITY to a Developer ID to distribute; notarization also
# needs a secure timestamp, so use CODESIGN_FLAGS="--options runtime --timestamp" then.
SIGN_IDENTITY ?= -
CODESIGN_FLAGS ?= --options runtime --timestamp=none
# Stamped into the bundle when set, for example by CI from a release tag.
VERSION ?=
BUILD_NUMBER ?=
DIST_NAME ?= Havbunn
INSTALL_DIR := $(HOME)/Library/Screen Savers

.PHONY: all saver dist tools install uninstall run clean

all: saver

saver: $(CONTENTS)/MacOS/Havbunn $(CONTENTS)/Resources/Shaders.metal $(CONTENTS)/Info.plist
	@if [ -f Resources/thumbnail.png ]; then cp Resources/thumbnail.png Resources/thumbnail@2x.png $(CONTENTS)/Resources/; fi
	@cp Resources/Info.plist $(CONTENTS)/Info.plist
	@if [ -n "$(VERSION)" ]; then plutil -replace CFBundleShortVersionString -string "$(VERSION)" $(CONTENTS)/Info.plist; fi
	@if [ -n "$(BUILD_NUMBER)" ]; then plutil -replace CFBundleVersion -string "$(BUILD_NUMBER)" $(CONTENTS)/Info.plist; fi
	codesign --force --sign "$(SIGN_IDENTITY)" $(CODESIGN_FLAGS) $(SAVER)

# Zip that keeps the bundle and its signature intact.
dist: saver
	rm -f $(BUILD)/$(DIST_NAME).zip
	ditto -c -k --keepParent $(SAVER) $(BUILD)/$(DIST_NAME).zip

$(CONTENTS)/MacOS/Havbunn: $(ENGINE) Sources/Saver/HavbunnView.swift
	@mkdir -p $(CONTENTS)/MacOS $(BUILD)/arm64 $(BUILD)/x86_64
	$(SWIFTC) -target arm64-apple-macos$(TARGET) -module-name Havbunn -emit-library -Xlinker -bundle -o $(BUILD)/arm64/Havbunn $(ENGINE) Sources/Saver/HavbunnView.swift -framework ScreenSaver
	$(SWIFTC) -target x86_64-apple-macos$(TARGET) -module-name Havbunn -emit-library -Xlinker -bundle -o $(BUILD)/x86_64/Havbunn $(ENGINE) Sources/Saver/HavbunnView.swift -framework ScreenSaver
	xcrun lipo -create $(BUILD)/arm64/Havbunn $(BUILD)/x86_64/Havbunn -output $@

# Compiled by Metal at load time, so building needs no Metal toolchain.
$(CONTENTS)/Resources/Shaders.metal: Sources/Shaders/Shaders.metal
	@mkdir -p $(CONTENTS)/Resources
	cp $< $@

$(CONTENTS)/Info.plist: Resources/Info.plist
	@mkdir -p $(CONTENTS)
	cp $< $@

# Offscreen frame renderer and a windowed host for the built bundle.
tools: $(BUILD)/havbunn-render $(BUILD)/havbunn-preview

$(BUILD)/havbunn-render: $(ENGINE) Tools/render.swift
	@mkdir -p $(BUILD)
	$(SWIFTC) -target arm64-apple-macos$(TARGET) -module-name HavbunnRender -parse-as-library -o $@ $(ENGINE) Tools/render.swift

$(BUILD)/havbunn-preview: Tools/preview.swift
	@mkdir -p $(BUILD)
	$(SWIFTC) -target arm64-apple-macos$(TARGET) -module-name HavbunnPreview -parse-as-library -o $@ Tools/preview.swift -framework ScreenSaver

run: saver $(BUILD)/havbunn-preview
	$(BUILD)/havbunn-preview $(SAVER)

install: saver
	@mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALL_DIR)/Havbunn.saver"
	cp -R $(SAVER) "$(INSTALL_DIR)/"
	-killall legacyScreenSaver 2>/dev/null
	@echo "Installed. Select Havbunn in System Settings > Screen Saver."

uninstall:
	rm -rf "$(INSTALL_DIR)/Havbunn.saver"

clean:
	rm -rf $(BUILD)
