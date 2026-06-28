#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="CleanMac"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' CleanMac/Info.plist)"
TEAM_ID="477K4S3LV2"
BUILD_DIR="$ROOT/build"
DERIVED="$BUILD_DIR/DerivedData"
APP_PATH="$DERIVED/Build/Products/Release/${APP_NAME}.app"
DMG_STAGING="$BUILD_DIR/dmg-staging"
DMG_OUTPUT="$BUILD_DIR/${APP_NAME}-${VERSION}.dmg"

if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  SIGN_IDENTITY="Developer ID Application"
else
  SIGN_IDENTITY="Apple Development"
  echo "Uyarı: Developer ID Application sertifikası yok. Apple Development ile imzalanıyor."
fi

echo ">> Release derlemesi (${SIGN_IDENTITY})"
xcodebuild \
  -project CleanMac.xcodeproj \
  -scheme cleanmac-mac \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="$SIGN_IDENTITY" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  clean build

echo ">> DMG oluşturuluyor"
rm -rf "$DMG_STAGING" "$DMG_OUTPUT"
mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/"
ln -sf /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_OUTPUT"

if [[ "$SIGN_IDENTITY" == "Developer ID Application" ]]; then
  echo ">> Notarizasyon (Keychain'de notarytool kimlik bilgisi gerekir)"
  xcrun notarytool submit "$DMG_OUTPUT" --keychain-profile "CleanMac-Notary" --wait
  xcrun stapler staple "$DMG_OUTPUT"
fi

echo ">> Tamam: $DMG_OUTPUT"
codesign -dv --verbose=4 "$APP_PATH" 2>&1 | grep -E "Authority|TeamIdentifier|Identifier"
