#!/usr/bin/env bash
# Build Remind.me.app in Release configuration and package it as a DMG.
# Output: dist/Remind.me-<version>.dmg
#
# Requires: xcodegen, Xcode 15+. No third-party DMG tools — uses hdiutil.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Resolve version from project.yml (CFBundleShortVersionString).
VERSION="$(awk -F'"' '/CFBundleShortVersionString/{print $2; exit}' project.yml)"
VERSION="${VERSION:-0.0.0}"

BUILD_DIR="$ROOT/build"
DIST_DIR="$ROOT/dist"
APP_NAME="Remind.me"
APP_BUNDLE="$BUILD_DIR/Build/Products/Release/${APP_NAME}.app"
DMG_NAME="Remind.me-${VERSION}.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
STAGING="$BUILD_DIR/dmg-staging"

echo "▸ Generating Xcode project"
xcodegen generate

echo "▸ Building Release"
xcodebuild -project RemindMe.xcodeproj \
  -scheme RemindMe \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  clean build | xcpretty || xcodebuild -project RemindMe.xcodeproj \
  -scheme RemindMe \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  clean build

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "✗ Build did not produce $APP_BUNDLE" >&2
  exit 1
fi

echo "▸ Staging DMG contents"
mkdir -p "$DIST_DIR"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "▸ Creating DMG"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -fs HFS+ \
  -format UDZO \
  "$DMG_PATH" >/dev/null

echo "✓ $DMG_PATH"
