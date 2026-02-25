.PHONY: build app dmg release clean install uninstall help

APP_NAME = Snape
VERSION = $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" resources/Info.plist)
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
DMG_NAME = $(APP_NAME)-$(VERSION)-macos.dmg
INSTALL_DIR = /Applications

# Build release binary
build:
	swift build -c release

# Create .app bundle
app: build
	@echo "Creating app bundle..."
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp .build/release/snape "$(APP_BUNDLE)/Contents/MacOS/"
	@cp resources/Info.plist "$(APP_BUNDLE)/Contents/"
	@swift scripts/create_icon.swift
	@iconutil -c icns /tmp/AppIcon.iconset -o "$(APP_BUNDLE)/Contents/Resources/AppIcon.icns"
	@rm -rf /tmp/AppIcon.iconset
	@echo "App bundle created: $(APP_BUNDLE)"

# Create DMG for distribution
dmg: app
	@echo "Creating DMG..."
	@rm -f "$(BUILD_DIR)/$(DMG_NAME)"
	@hdiutil create -volname "$(APP_NAME)" -srcfolder "$(APP_BUNDLE)" -ov -format UDZO "$(BUILD_DIR)/$(DMG_NAME)"
	@echo "DMG created: $(BUILD_DIR)/$(DMG_NAME)"

# Full release (clean + build + app + dmg)
release: clean dmg
	@echo ""
	@echo "Release complete!"
	@echo "  App: $(APP_BUNDLE)"
	@echo "  DMG: $(BUILD_DIR)/$(DMG_NAME)"
	@ls -lh "$(BUILD_DIR)/$(DMG_NAME)"

# Install to /Applications
install: app
	@echo "Installing to $(INSTALL_DIR)..."
	@sudo cp -r "$(APP_BUNDLE)" "$(INSTALL_DIR)/"
	@echo "Installed: $(INSTALL_DIR)/$(APP_NAME).app"

# Uninstall from /Applications
uninstall:
	@echo "Removing $(INSTALL_DIR)/$(APP_NAME).app..."
	@sudo rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Uninstalled"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
	@rm -rf .build
	@echo "Clean complete"

# Help
help:
	@echo "Snape - Build targets:"
	@echo ""
	@echo "  make build     - Build release binary"
	@echo "  make app       - Create .app bundle"
	@echo "  make dmg       - Create DMG for distribution"
	@echo "  make release   - Full release (clean + dmg)"
	@echo "  make install   - Install to /Applications"
	@echo "  make uninstall - Remove from /Applications"
	@echo "  make clean     - Remove build artifacts"
	@echo "  make help      - Show this help"
