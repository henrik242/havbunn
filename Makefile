BUILD := build
APP := $(BUILD)/Havbunn.app
APPEX := $(APP)/Contents/PlugIns/Havbunn.appex
ENGINE := $(wildcard Sources/Engine/*.swift Sources/Engine/Species/*.swift)
SAVER := $(wildcard Sources/Saver/*.swift)
EXTENSION := $(wildcard Sources/Extension/*.swift)
# Apple Silicon only: macOS 26 was the last release for Intel Macs.
TARGET := 27.0
SDK := $(shell xcrun --sdk macosx --show-sdk-path)
SWIFTC := xcrun swiftc -sdk $(SDK) -swift-version 5 -O -whole-module-optimization
# Ad-hoc by default. Set SIGN_IDENTITY to a Developer ID to distribute; notarization also
# needs a secure timestamp, so use CODESIGN_FLAGS="--options runtime --timestamp" then.
SIGN_IDENTITY ?= -
CODESIGN_FLAGS ?= --options runtime --timestamp=none
# Stamped into the bundles when set, for example by CI from a release tag.
VERSION ?=
BUILD_NUMBER ?=
DIST_NAME ?= Havbunn
INSTALL_DIR := $(HOME)/Applications

.PHONY: all app dist tools check golden install uninstall run clean

all: app

# The app carries the screen saver as an app extension. Sign inside out.
app: $(APPEX)/Contents/MacOS/Havbunn $(APPEX)/Contents/Resources/Shaders.metal $(APPEX)/Contents/Resources/Assets.car $(APP)/Contents/MacOS/Havbunn
	@cp Resources/Extension-Info.plist $(APPEX)/Contents/Info.plist
	@cp Resources/App-Info.plist $(APP)/Contents/Info.plist
	@for p in $(APPEX)/Contents/Info.plist $(APP)/Contents/Info.plist; do \
		if [ -n "$(VERSION)" ]; then plutil -replace CFBundleShortVersionString -string "$(VERSION)" $$p; fi; \
		if [ -n "$(BUILD_NUMBER)" ]; then plutil -replace CFBundleVersion -string "$(BUILD_NUMBER)" $$p; fi; \
	done
	codesign --force --sign "$(SIGN_IDENTITY)" $(CODESIGN_FLAGS) --entitlements Resources/Extension.entitlements $(APPEX)
	codesign --force --sign "$(SIGN_IDENTITY)" $(CODESIGN_FLAGS) $(APP)

# Zip that keeps the bundle and its signature intact.
dist: app
	rm -f $(BUILD)/$(DIST_NAME).zip
	ditto -c -k --keepParent $(APP) $(BUILD)/$(DIST_NAME).zip

# The extension's entry point is Foundation's NSExtensionMain; the classes it subclasses are
# declared in ScreenSaverPrivate.h.
$(APPEX)/Contents/MacOS/Havbunn: $(ENGINE) $(SAVER) $(EXTENSION) Sources/Extension/ScreenSaverPrivate.h
	@mkdir -p $(@D)
	$(SWIFTC) -target arm64-apple-macos$(TARGET) -module-name Havbunn -parse-as-library -application-extension \
		-import-objc-header Sources/Extension/ScreenSaverPrivate.h -Xcc -DGL_SILENCE_DEPRECATION \
		-o $@ $(ENGINE) $(SAVER) $(EXTENSION) -framework ScreenSaver \
		-Xlinker -e -Xlinker _NSExtensionMain -Xlinker -application_extension

# Compiled by Metal at load time, so building needs no Metal toolchain.
$(APPEX)/Contents/Resources/Shaders.metal: Sources/Shaders/Shaders.metal
	@mkdir -p $(@D)
	cp $< $@

# The thumbnail System Settings shows.
$(APPEX)/Contents/Resources/Assets.car: $(wildcard Resources/Assets.xcassets/*/* Resources/Assets.xcassets/*)
	@mkdir -p $(@D)
	xcrun actool Resources/Assets.xcassets --compile $(@D) --platform macosx --minimum-deployment-target $(TARGET) \
		--output-partial-info-plist $(BUILD)/assets-info.plist > /dev/null

$(APP)/Contents/MacOS/Havbunn: Sources/App/main.swift
	@mkdir -p $(@D)
	$(SWIFTC) -target arm64-apple-macos$(TARGET) -module-name HavbunnApp -o $@ Sources/App/main.swift

# Offscreen frame renderer, a windowed host for the saver view, and inspection tools.
tools: $(BUILD)/havbunn-render $(BUILD)/havbunn-preview $(BUILD)/havbunn-sprite $(BUILD)/havbunn-trace

$(BUILD)/havbunn-render: $(ENGINE) Tools/render.swift
	@mkdir -p $(BUILD)
	$(SWIFTC) -target arm64-apple-macos$(TARGET) -module-name HavbunnRender -parse-as-library -o $@ $(ENGINE) Tools/render.swift

# Renders a single sprite (or all) to PNGs for inspecting one species at a time.
$(BUILD)/havbunn-sprite: $(ENGINE) Tools/sprite.swift
	@mkdir -p $(BUILD)
	$(SWIFTC) -target arm64-apple-macos$(TARGET) -module-name HavbunnSprite -parse-as-library -o $@ $(ENGINE) Tools/sprite.swift

# GPU-free scene fingerprint, to catch unintended changes to placement, behaviour or art.
$(BUILD)/havbunn-trace: $(ENGINE) Tools/trace.swift
	@mkdir -p $(BUILD)
	$(SWIFTC) -target arm64-apple-macos$(TARGET) -module-name HavbunnTrace -parse-as-library -o $@ $(ENGINE) Tools/trace.swift

check: $(BUILD)/havbunn-trace
	$(BUILD)/havbunn-trace | diff -u Tools/trace.golden - && echo "Scene unchanged."

# After an intended change to the scene.
golden: $(BUILD)/havbunn-trace
	$(BUILD)/havbunn-trace > Tools/trace.golden

# An extension cannot be loaded into another process, so the preview builds the view in.
$(BUILD)/havbunn-preview: $(ENGINE) $(SAVER) Tools/preview.swift
	@mkdir -p $(BUILD)
	$(SWIFTC) -target arm64-apple-macos$(TARGET) -module-name HavbunnPreview -parse-as-library -Xcc -DGL_SILENCE_DEPRECATION \
		-o $@ $(ENGINE) $(SAVER) Tools/preview.swift -framework ScreenSaver

run: $(BUILD)/havbunn-preview
	$(BUILD)/havbunn-preview

# One registered copy only: the system may load a stale one otherwise.
install: app
	rm -rf "$(HOME)/Library/Screen Savers/Havbunn.saver"
	@mkdir -p "$(INSTALL_DIR)"
	-pluginkit -r "$(INSTALL_DIR)/Havbunn.app/Contents/PlugIns/Havbunn.appex" 2>/dev/null
	-pluginkit -r "$(APPEX)" 2>/dev/null
	rm -rf "$(INSTALL_DIR)/Havbunn.app"
	ditto $(APP) "$(INSTALL_DIR)/Havbunn.app"
	open "$(INSTALL_DIR)/Havbunn.app"
	@echo "Installed. Choose Havbunn in System Settings > Wallpaper, under Screen Saver."

uninstall:
	-pluginkit -r "$(INSTALL_DIR)/Havbunn.app/Contents/PlugIns/Havbunn.appex" 2>/dev/null
	rm -rf "$(INSTALL_DIR)/Havbunn.app" "$(HOME)/Library/Screen Savers/Havbunn.saver"

clean:
	rm -rf $(BUILD)
