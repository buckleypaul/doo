#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/Applications/Doo.app"
VERSION="1.0"

echo "Building Doo release binary..."
cd "$SCRIPT_DIR"
swift build -c release

echo "Assembling $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"

sed "s/BUNDLE_VERSION_PLACEHOLDER/$VERSION/g" \
    "$SCRIPT_DIR/Support/Info.plist" \
    > "$APP_DIR/Contents/Info.plist"

cp "$SCRIPT_DIR/.build/release/Doo" "$APP_DIR/Contents/MacOS/Doo"
chmod +x "$APP_DIR/Contents/MacOS/Doo"

echo "Installing CLI to /usr/local/bin/doo..."
sudo cp "$SCRIPT_DIR/.build/release/DooCLI" /usr/local/bin/doo

echo ""
echo "Done:"
echo "  GUI → $APP_DIR"
echo "  CLI → /usr/local/bin/doo"
