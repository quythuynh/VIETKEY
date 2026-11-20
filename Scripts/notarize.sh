#!/bin/zsh
# Builds a Release vietKey.app signed with Developer ID, notarizes it and packages a DMG.
#
# One-time setup:
#   1. A "Developer ID Application" certificate in your keychain.
#   2. Store notary credentials:
#        xcrun notarytool store-credentials vietKey-notary \
#            --apple-id you@example.com --team-id JHQ7BLPWB5 --password <app-specific-password>
#
# Usage:
#   Scripts/notarize.sh                 # uses keychain profile "vietKey-notary"
#   NOTARY_PROFILE=other Scripts/notarize.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/.build-release"
PROFILE="${NOTARY_PROFILE:-vietKey-notary}"
TEAM_ID="${TEAM_ID:-JHQ7BLPWB5}"

rm -rf "$BUILD"
mkdir -p "$BUILD"

xcodebuild -project "$ROOT/vietKey.xcodeproj" -scheme vietKey -configuration Release \
    -archivePath "$BUILD/vietKey.xcarchive" archive -quiet

cat > "$BUILD/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>developer-id</string>
    <key>teamID</key><string>$TEAM_ID</string>
    <key>signingStyle</key><string>automatic</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive -archivePath "$BUILD/vietKey.xcarchive" \
    -exportOptionsPlist "$BUILD/ExportOptions.plist" -exportPath "$BUILD/export" -quiet

APP="$BUILD/export/vietKey.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
DMG="$BUILD/vietKey-$VERSION.dmg"

# The DMG holds the app; opening it from there runs the built-in installer.
hdiutil create -volname "vietKey $VERSION" -srcfolder "$APP" -ov -format UDZO "$DMG"

xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"

echo "Done: $DMG"
