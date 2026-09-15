#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
VERSION=$(tr -d '\n' < VERSION)
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid VERSION' >&2; exit 1; }
mkdir -p .build
STAGING=$(mktemp -d "$PWD/.build/staging.XXXXXX")
trap 'rm -rf "$STAGING"' EXIT
APP="$STAGING/NodePeek.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -swift-version 5 -O -parse-as-library -target arm64-apple-macosx13.0 Sources/*.swift -o "$APP/Contents/MacOS/NodePeek"
cp Resources/AppIcon.icns Resources/MenuIcon.png Resources/collector.py "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>NodePeek</string>
<key>CFBundleIdentifier</key><string>local.remotemeter.app</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleName</key><string>NodePeek</string>
<key>CFBundleDisplayName</key><string>NodePeek</string>
<key>CFBundleVersion</key><string>12</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleLocalizations</key><array><string>en</string><string>zh-Hans</string></array>
<key>LSUIElement</key><false/>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
# Replace only the generated app after compilation and verification have succeeded.
if [[ -d NodePeek.app ]]; then mv NodePeek.app "$STAGING/previous.app"; fi
mv "$APP" NodePeek.app
printf 'Built %s/NodePeek.app (%s)\n' "$PWD" "$VERSION"
