#!/bin/zsh
# Installs the built vietKey.app into ~/Library/Input Methods for local testing.
#
# Usage:
#   Scripts/install-dev.sh          Build (Debug) with xcodebuild, then install.
#   As a Scheme → Build → Post-action, with "Provide build settings from: vietKey":
#       "$SRCROOT/Scripts/install-dev.sh"
#   In that case the app Xcode just built ($BUILT_PRODUCTS_DIR) is installed, no rebuild.
#
# First time only: System Settings → Keyboard → Input Sources → + → Vietnamese → vietKey.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/Library/Input Methods"
APP_NAME="vietKey.app"

if [[ -n "${BUILT_PRODUCTS_DIR:-}" ]]; then
    APP="$BUILT_PRODUCTS_DIR/$APP_NAME"
else
    xcodebuild -project "$ROOT/vietKey.xcodeproj" -scheme vietKey -configuration Debug \
        -derivedDataPath "$ROOT/.build-dev" build -quiet
    APP="$ROOT/.build-dev/Build/Products/Debug/$APP_NAME"
fi

[[ -d "$APP" ]] || { echo "error: $APP not found" >&2; exit 1; }

# The system keeps the old process (and its code) alive; stop it so the new build is loaded.
pkill -x vietKey 2>/dev/null || true

mkdir -p "$DEST"
rm -rf "$DEST/$APP_NAME"
cp -R "$APP" "$DEST/"

# Register so the input source shows up without logging out.
swift - "$DEST/$APP_NAME" <<'EOF'
import Carbon
import Foundation

let url = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
let status = TISRegisterInputSource(url)
print(status == noErr ? "Registered input source" : "TISRegisterInputSource failed: \(status)")
EOF

echo "Installed $DEST/$APP_NAME"
