BUILD := build
SAVER := $(BUILD)/Havbunn.saver
CONTENTS := $(SAVER)/Contents
ENGINE := $(wildcard Sources/Engine/*.swift)
TARGET := 12.0
SDK := $(shell xcrun --sdk macosx --show-sdk-path)
SWIFTC := xcrun swiftc -sdk $(SDK) -swift-version 5 -O -whole-module-optimization
# Ad-hoc by default. Set SIGN_IDENTITY to a Developer ID to distribute.
SIGN_IDENTITY ?= -
INSTALL_DIR := $(HOME)/Library/Screen Savers

.PHONY: all saver tools install uninstall run clean

all: saver

saver: $(CONTENTS)/MacOS/Havbunn $(CONTENTS)/Resources/Shaders.metal $(CONTENTS)/Info.plist
	@if [ -f Resources/thumbnail.png ]; then cp Resources/thumbnail.png Resources/thumbnail@2x.png $(CONTENTS)/Resources/; fi
	codesign --force --sign "$(SIGN_IDENTITY)" --options runtime --timestamp=none $(SAVER)

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
