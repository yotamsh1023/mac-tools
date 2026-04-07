APP_NAME  = ClipBoard
APP_BUNDLE = $(APP_NAME).app
SDK       = $(shell xcrun --show-sdk-path)
SWIFTC    = swiftc
SOURCES   = $(shell find Sources/ClipBoard -name '*.swift' | sort)
BUILD_DIR = .build
BINARY    = $(BUILD_DIR)/$(APP_NAME)

SWIFTFLAGS = \
	-sdk $(SDK) \
	-target arm64-apple-macos13.0 \
	-framework AppKit \
	-framework Carbon \
	-lsqlite3 \
	-O \
	-whole-module-optimization

build: $(BUILD_DIR)
	$(SWIFTC) $(SWIFTFLAGS) $(SOURCES) -o $(BINARY)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

bundle: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BINARY) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp Resources/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	chmod +x $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)

run: bundle
	open $(APP_BUNDLE)

install: bundle
	cp -R $(APP_BUNDLE) /Applications/

clean:
	rm -rf $(BUILD_DIR) $(APP_BUNDLE)

.PHONY: build bundle run install clean
