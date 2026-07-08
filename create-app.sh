#!/bin/bash
# Build the app and create a proper .app bundle
set -euo pipefail

BUILD_DIR="/Users/jonathan/Documents/GitHub/prisma/projects/opencode-rate-checker"
APP_NAME="RateLimitAgent"
APP_BUNDLE="$BUILD_DIR/build/$APP_NAME.app"

echo "🔨 Building..."
cd "$BUILD_DIR"
swift build -c release 2>&1

BINARY_PATH=$(swift build -c release --show-bin-path 2>/dev/null)/$APP_NAME
echo "✅ Binary at: $BINARY_PATH"

echo "📦 Creating .app bundle at $APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Info.plist with LSUIElement=true (no dock icon, menu bar only)
cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.opencode.rate-limit-agent</string>
    <key>CFBundleName</key>
    <string>OpenCode Rate Limit</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "✅ App bundle created at: $APP_BUNDLE"
echo ""
echo "To run: open \"$APP_BUNDLE\""
echo "Or:     $APP_BUNDLE/Contents/MacOS/$APP_NAME"
