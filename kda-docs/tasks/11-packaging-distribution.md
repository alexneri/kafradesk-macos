# Task 11: macOS Packaging and Distribution

## Goal
Prepare the Kafra Desktop Assistant for secure distribution on macOS with proper code signing, notarization, and a professional installer.

## Scope
- Configure code signing with Apple Developer ID
- Define app entitlements for file system access
- Set up notarization workflow for macOS 10.15+
- Create a DMG installer with branding
- Test distribution on clean macOS systems
- Support Dark Mode and modern macOS conventions

## Implementation Steps

### 1. Code Signing Configuration

**Xcode Project Settings:**
```
1. Open project in Xcode
2. Select target → Signing & Capabilities
3. Enable "Automatically manage signing" OR configure manual provisioning
4. Select Team (requires Apple Developer account)
5. Set Bundle Identifier: moe.sei.kafra-desktop-assistant
```

**Create signing certificate:**
```bash
# Request Developer ID Application certificate from Apple Developer portal
# Download and install in Keychain Access
# Verify with:
security find-identity -v -p codesigning
```

### 2. App Entitlements

Create `Kafra Desktop Assistant/Kafra Desktop Assistant/Kafra_Desktop_Assistant.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Allow read/write to user-selected files (drag-drop) -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Allow read/write to Application Support directory -->
    <key>com.apple.security.files.bookmarks.app-scope</key>
    <true/>
    
    <!-- Allow opening files in default applications -->
    <key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
    <array>
        <string>/Users/</string>
    </array>
    
    <!-- Disable network access (not needed) -->
    <key>com.apple.security.network.client</key>
    <false/>
    
    <key>com.apple.security.network.server</key>
    <false/>
    
    <!-- Enable hardened runtime -->
    <key>com.apple.security.cs.allow-jit</key>
    <false/>
    
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <false/>
    
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <false/>
    
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>
</dict>
</plist>
```

**Link entitlements in Xcode:**
- Target → Build Settings → Code Signing Entitlements
- Set to: `Kafra Desktop Assistant/Kafra_Desktop_Assistant.entitlements`

### 3. Info.plist Configuration

Update `Info.plist` with required keys:

```xml
<!-- App metadata -->
<key>CFBundleName</key>
<string>Kafra Desktop Assistant</string>

<key>CFBundleDisplayName</key>
<string>Kafra Desktop</string>

<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

<key>CFBundleVersion</key>
<string>1.0.0</string>

<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<!-- Minimum macOS version -->
<key>LSMinimumSystemVersion</key>
<string>13.0</string>

<!-- UI Mode: Agent app (no dock icon by default) -->
<key>LSUIElement</key>
<true/>

<!-- High resolution support -->
<key>NSHighResolutionCapable</key>
<true/>

<!-- Privacy usage descriptions -->
<key>NSDesktopFolderUsageDescription</key>
<string>Kafra Desktop Assistant needs access to your Desktop to manage files you drag and drop.</string>

<key>NSDocumentsFolderUsageDescription</key>
<string>Kafra Desktop Assistant needs access to your Documents to manage files you drag and drop.</string>

<key>NSDownloadsFolderUsageDescription</key>
<string>Kafra Desktop Assistant needs access to your Downloads to manage files you drag and drop.</string>

<!-- Dark mode support -->
<key>NSRequiresAquaSystemAppearance</key>
<false/>

<!-- Copyright -->
<key>NSHumanReadableCopyright</key>
<string>Copyright © 2026 SG Reserach | Crosse_. Fan work inspired by Ragnarok Online.</string>

<!-- Category -->
<key>LSApplicationCategoryType</key>
<string>public.app-category.utilities</string>
```

### 4. Build Configuration

**Create Archive Build Script:**

Create `scripts/build-release.sh`:

```bash
#!/bin/bash
set -e

PROJECT_NAME="Kafra Desktop Assistant"
SCHEME="Kafra Desktop Assistant"
ARCHIVE_PATH="build/Kafra_Desktop_Assistant.xcarchive"
EXPORT_PATH="build/export"
APP_NAME="Kafra Desktop Assistant.app"

echo "🏗️  Building $PROJECT_NAME..."

# Clean build folder
rm -rf build
mkdir -p build

# Create archive
xcodebuild archive \
    -project "Kafra Desktop Assistant/Kafra Desktop Assistant.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="YOUR_TEAM_ID"

# Export app
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "scripts/ExportOptions.plist"

echo "✅ Build complete: $EXPORT_PATH/$APP_NAME"
```

**Create Export Options:**

Create `scripts/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    
    <key>signingStyle</key>
    <string>automatic</string>
    
    <key>uploadSymbols</key>
    <true/>
    
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

### 5. Notarization Setup

**Create Notarization Script:**

Create `scripts/notarize.sh`:

```bash
#!/bin/bash
set -e

APP_PATH="build/export/Kafra Desktop Assistant.app"
BUNDLE_ID="moe.sei.kafra-desktop-assistant"
ZIP_PATH="build/Kafra_Desktop_Assistant.zip"

# Store credentials in keychain:
# xcrun notarytool store-credentials "AC_PASSWORD" \
#   --apple-id "your@email.com" \
#   --team-id "YOUR_TEAM_ID" \
#   --password "app-specific-password"

echo "📦 Creating ZIP for notarization..."
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "🔐 Submitting for notarization..."
xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "AC_PASSWORD" \
    --wait

echo "📋 Getting submission info..."
xcrun notarytool info <SUBMISSION_ID> \
    --keychain-profile "AC_PASSWORD"

echo "✅ Stapling ticket to app..."
xcrun stapler staple "$APP_PATH"

echo "🎉 Notarization complete!"
```

**Make scripts executable:**
```bash
chmod +x scripts/build-release.sh
chmod +x scripts/notarize.sh
```

### 6. DMG Creation

**Create DMG Build Script:**

Create `scripts/create-dmg.sh`:

```bash
#!/bin/bash
set -e

APP_PATH="build/export/Kafra Desktop Assistant.app"
DMG_PATH="build/Kafra_Desktop_Assistant_v1.0.0.dmg"
VOLUME_NAME="Kafra Desktop Assistant"
BACKGROUND_PATH="assets/dmg-background.png"

echo "💿 Creating DMG installer..."

# Create temporary DMG
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$APP_PATH" \
    -ov -format UDZO \
    "$DMG_PATH"

# Optional: Create styled DMG with background
# Requires create-dmg tool: brew install create-dmg

create-dmg \
    --volname "$VOLUME_NAME" \
    --volicon "assets/AppIcon.icns" \
    --background "$BACKGROUND_PATH" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "Kafra Desktop Assistant.app" 150 200 \
    --hide-extension "Kafra Desktop Assistant.app" \
    --app-drop-link 450 200 \
    "$DMG_PATH" \
    "$APP_PATH"

echo "✅ DMG created: $DMG_PATH"

# Verify DMG signature
codesign --verify --deep --strict "$DMG_PATH"
spctl --assess --type open --context context:primary-signature "$DMG_PATH"
```

### 7. Dark Mode Support

**Update SwiftUI Views:**

```swift
// Ensure all views adapt to system appearance
struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        // Use adaptive colors
        Text("Kafra")
            .foregroundColor(.primary)
            .background(Color(NSColor.windowBackgroundColor))
    }
}

// For AppKit windows
class MascotWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Allow automatic appearance switching
        window?.appearance = nil
    }
}
```

### 8. Accessibility Support

**Add Accessibility Labels:**

```swift
// Status bar icon
statusItem.button?.toolTip = "Kafra Desktop Assistant"

// Mascot window
mascotView.accessibilityLabel = "Kafra character mascot"
mascotView.accessibilityHint = "Drag to move the mascot around your screen"

// Menu items
menuItem.accessibilityLabel = "Show Kafra mascot"
```

**Support keyboard navigation:**

```swift
// Ensure all interactive elements are keyboard accessible
Button("Save Memo") { ... }
    .keyboardShortcut("s", modifiers: .command)
```

### 9. Testing Distribution

**Create Testing Checklist:**

```markdown
## Pre-Release Testing

### Clean System Test
- [ ] Test on macOS 13.0 (minimum supported version)
- [ ] Test on macOS 14.x (Sonoma)
- [ ] Test on macOS 15.x (Sequoia) if available
- [ ] Test on both Intel and Apple Silicon

### Gatekeeper Test
- [ ] Copy DMG to test Mac without Developer tools
- [ ] Double-click DMG, drag app to Applications
- [ ] Launch app - should NOT show "Unidentified Developer" warning
- [ ] Verify app functionality
- [ ] Check Console.app for errors

### Entitlements Test
- [ ] Drop files onto mascot - should work without permission dialog
- [ ] Check Storage folder access - should be automatic
- [ ] Verify no unexpected permission prompts
- [ ] Test file operations (open, delete, move)

### Code Signature Verification
```bash
# Verify app signature
codesign --verify --deep --strict "Kafra Desktop Assistant.app"

# Check entitlements
codesign --display --entitlements - "Kafra Desktop Assistant.app"

# Verify notarization
spctl --assess --verbose "Kafra Desktop Assistant.app"

# Check Gatekeeper status
xattr -lr "Kafra Desktop Assistant.app"
```

### Dark Mode Test
- [ ] Switch to Dark Mode - UI adapts correctly
- [ ] Switch to Light Mode - UI adapts correctly
- [ ] Test with "Auto" appearance setting

### Multi-Monitor Test
- [ ] Mascot stays on correct screen when dragged
- [ ] Status bar icon appears on all screens
- [ ] Window position persists across displays
```

### 10. Distribution Workflow

**Complete Release Process:**

```bash
# 1. Build release archive
./scripts/build-release.sh

# 2. Notarize the app
./scripts/notarize.sh

# 3. Create DMG installer
./scripts/create-dmg.sh

# 4. Verify signatures
codesign --verify --deep --strict "build/export/Kafra Desktop Assistant.app"
codesign --verify --strict "build/Kafra_Desktop_Assistant_v1.0.0.dmg"

# 5. Test on clean system
# Copy DMG to test Mac and verify installation

# 6. Upload to distribution platform
# - GitHub Releases
# - Personal website
# - Homebrew cask (optional)
```

## Acceptance Criteria

### Code Signing
- [ ] App is signed with valid Developer ID Application certificate
- [ ] Entitlements file is correctly configured and applied
- [ ] Hardened runtime is enabled
- [ ] Signature verification passes: `codesign --verify --deep --strict`

### Notarization
- [ ] App successfully passes Apple notarization
- [ ] Notarization ticket is stapled to app bundle
- [ ] Gatekeeper assessment passes: `spctl --assess --verbose`
- [ ] No "Unidentified Developer" warning on launch

### DMG Installer
- [ ] DMG mounts cleanly on macOS 13.0+
- [ ] Visual presentation is professional (icon, background)
- [ ] Drag-to-Applications workflow is intuitive
- [ ] DMG signature is valid

### System Integration
- [ ] App launches on clean macOS without errors
- [ ] Status bar icon appears correctly
- [ ] Mascot window renders with transparency
- [ ] File permissions work without manual approval

### Platform Support
- [ ] Works on macOS 13.0 Ventura (minimum)
- [ ] Works on macOS 14.x Sonoma
- [ ] Works on macOS 15.x Sequoia (if available)
- [ ] Works on Intel and Apple Silicon Macs

### Modern macOS Conventions
- [ ] Dark Mode automatically adapts
- [ ] Accessibility labels are present
- [ ] High resolution displays render correctly
- [ ] Privacy descriptions are in Info.plist

### Documentation
- [ ] Installation instructions in README
- [ ] Uninstall instructions provided
- [ ] Known issues documented
- [ ] Support contact information included

## Notes/Dependencies

### Prerequisites
- Apple Developer account ($99/year) for Developer ID certificate
- Xcode 15.0+ for latest SDK support
- macOS 13.0+ for building
- `create-dmg` tool: `brew install create-dmg`

### Dependencies
- Depends on all previous tasks (01-10) being complete
- Requires app to be fully functional before packaging
- Asset preparation (icons, DMG background)

### Distribution Options

**Option A: Direct Download (Recommended)**
- Host DMG on GitHub Releases or personal server
- No App Store review process
- Maximum flexibility
- Requires Developer ID certificate + notarization

**Option B: Mac App Store**
- Official distribution channel
- Automatic updates
- Sandboxing required (limits functionality)
- Lengthy review process
- Additional restrictions on file access

**Option C: Homebrew Cask**
- Package manager distribution
- Easy updates via `brew upgrade`
- Requires public DMG URL
- Popular among developers

### Security Considerations
- Never commit signing certificates to git
- Store notarization credentials in Keychain, not scripts
- Use app-specific passwords for notarization
- Rotate credentials periodically

### Future Enhancements
- Automatic update mechanism (Sparkle framework)
- Crash reporting integration
- Usage analytics (opt-in)
- Localization for multiple languages

---

**Task Priority:** High (required for any public distribution)  
**Estimated Effort:** 12-16 hours  
**Complexity:** Medium (many steps, but well-documented by Apple)
