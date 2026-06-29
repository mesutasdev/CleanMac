#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="CleanMac"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' CleanMac/Info.plist)"
TEAM_ID="477K4S3LV2"
BUILD_DIR="$ROOT/build"
mkdir -p "$BUILD_DIR"
touch "$BUILD_DIR/.metadata_never_index"
DERIVED="$BUILD_DIR/DerivedData"
ARCHIVE="$BUILD_DIR/CleanMac.xcarchive"
APP_PATH="$ARCHIVE/Products/Applications/${APP_NAME}.app"
DMG_STAGING="$BUILD_DIR/dmg-staging"
DMG_OUTPUT="$BUILD_DIR/${APP_NAME}-${VERSION}.dmg"
CA_CRT="$BUILD_DIR/certs/CleanMac-CA.crt"

if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  BUILD_IDENTITY="Developer ID Application"
  RESIGN_IDENTITY="Developer ID Application"
  CODE_SIGN_STYLE="Manual"
  USE_DEVELOPER_ID=1
elif security find-identity -v -p codesigning | grep -q "CleanMac Distribution"; then
  BUILD_IDENTITY="Apple Development"
  RESIGN_IDENTITY="CleanMac Distribution"
  CODE_SIGN_STYLE="Automatic"
else
  BUILD_IDENTITY="Apple Development"
  RESIGN_IDENTITY="$("$ROOT/scripts/create-distribution-cert.sh")"
  CODE_SIGN_STYLE="Automatic"
fi

echo ">> Archive (${BUILD_IDENTITY})"
xcodebuild \
  -project CleanMac.xcodeproj \
  -scheme cleanmac-mac \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  -archivePath "$ARCHIVE" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_IDENTITY="$BUILD_IDENTITY" \
  CODE_SIGN_STYLE="$CODE_SIGN_STYLE" \
  -allowProvisioningUpdates \
  clean archive

echo ">> İmzalama (${RESIGN_IDENTITY})"
/usr/bin/codesign --force --deep --sign "$RESIGN_IDENTITY" --options runtime --timestamp "$APP_PATH"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo ">> DMG"
rm -rf "$DMG_STAGING" "$DMG_OUTPUT"
mkdir -p "$DMG_STAGING"
ditto "$APP_PATH" "$DMG_STAGING/${APP_NAME}.app"
ln -sf /Applications "$DMG_STAGING/Applications"

if [[ "${USE_DEVELOPER_ID:-0}" -eq 1 ]]; then
  "$ROOT/scripts/create-installer-app.sh" "$DMG_STAGING" "$RESIGN_IDENTITY"
  cp "$ROOT/scripts/dmg-install-instructions-en.txt" "$DMG_STAGING/INSTALL.txt"
  cp "$ROOT/scripts/dmg-install-instructions-tr.txt" "$DMG_STAGING/KURULUM.txt"
elif [[ "$RESIGN_IDENTITY" != "Developer ID Application" ]]; then
  cp "$CA_CRT" "$DMG_STAGING/CleanMac-Root-CA.crt"
  cat > "$DMG_STAGING/KURULUM.txt" <<'EOF'
CleanMac — Kurulum (Geliştirici build)

YOL 1 — Sürükle bırak
  1) CleanMac.app dosyasını Applications klasörüne sürükleyin
  2) Applications klasöründen CleanMac'i açın

YOL 2 — İlk açılış uyarısı
  macOS uyarı verirse:
  - CleanMac-Root-CA.crt dosyasını çift tıklayın
  - Anahtar Zinciri Erişimi > Sistem > CleanMac Root CA
  - Güven > Kod imzalama için: Her Zaman Güven
  - CleanMac.app için Sağ tık > Aç > Aç
EOF
  cat > "$DMG_STAGING/INSTALL.txt" <<'EOF'
CleanMac — Installation (Developer build)

METHOD 1 — Drag and drop
  1) Drag CleanMac.app into the Applications folder
  2) Open CleanMac from Applications

METHOD 2 — First launch warning
  If macOS warns:
  - Double-click CleanMac-Root-CA.crt
  - Keychain Access > System > CleanMac Root CA > Always Trust
  - Right-click CleanMac.app > Open > Open
EOF
fi

hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_OUTPUT"
rm -rf "$DMG_STAGING"

if [[ "${USE_DEVELOPER_ID:-0}" -eq 1 ]]; then
  NOTARY_PROFILE="${NOTARY_PROFILE:-CleanMac-Notary}"
  echo ">> Notarizasyon (${NOTARY_PROFILE})"
  xcrun notarytool submit "$DMG_OUTPUT" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_OUTPUT"
  xcrun stapler validate "$DMG_OUTPUT"

  VERIFY_MOUNT=$(hdiutil attach "$DMG_OUTPUT" -nobrowse -plist | plutil -extract system-entities.0.mount-point raw - 2>/dev/null || true)
  if [[ -n "$VERIFY_MOUNT" && -d "$VERIFY_MOUNT/CleanMac.app" ]]; then
    if ! spctl -a -t exec -- "$VERIFY_MOUNT/CleanMac.app" >/dev/null 2>&1; then
      echo "HATA: CleanMac.app Gatekeeper doğrulaması başarısız" >&2
      hdiutil detach "$VERIFY_MOUNT" -quiet 2>/dev/null || true
      exit 1
    fi
    if ! spctl -a -t exec -- "$VERIFY_MOUNT/CleanMac'i Kur.app" >/dev/null 2>&1; then
      echo "HATA: CleanMac'i Kur.app Gatekeeper doğrulaması başarısız" >&2
      hdiutil detach "$VERIFY_MOUNT" -quiet 2>/dev/null || true
      exit 1
    fi
    hdiutil detach "$VERIFY_MOUNT" -quiet
    echo ">> Gatekeeper doğrulandı (CleanMac.app + CleanMac'i Kur.app)"
  fi
fi

echo ">> Hazır: $DMG_OUTPUT"
codesign -dv --verbose=4 "$APP_PATH" 2>&1 | grep -E "Authority|Identifier|TeamIdentifier|Signature"
