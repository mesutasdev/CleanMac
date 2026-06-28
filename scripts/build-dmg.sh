#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="CleanMac"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' CleanMac/Info.plist)"
TEAM_ID="477K4S3LV2"
BUILD_DIR="$ROOT/build"
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
cp "$ROOT/scripts/dmg-install.command" "$DMG_STAGING/CleanMac Kur.command"
chmod +x "$DMG_STAGING/CleanMac Kur.command"
ln -sf /Applications "$DMG_STAGING/Applications"

if [[ "${USE_DEVELOPER_ID:-0}" -eq 1 ]]; then
  cat > "$DMG_STAGING/KURULUM.txt" <<'EOF'
CleanMac kurulumu

ÖNERİLEN (eski sürüm açık olsa bile çalışır):
  1) "CleanMac Kur.command" dosyasına çift tıklayın
  2) Kurulum bitince uygulama otomatik açılır

Manuel kurulum:
  1) Önce CleanMac'i tamamen kapatın (menü çubuğu → CleanMac'den Çık)
  2) CleanMac.app → Applications klasörüne sürükleyin
  3) Uygulamayı açın
EOF
elif [[ "$RESIGN_IDENTITY" != "Developer ID Application" ]]; then
  cp "$CA_CRT" "$DMG_STAGING/CleanMac-Root-CA.crt"
  cat > "$DMG_STAGING/KURULUM.txt" <<'EOF'
CleanMac kurulumu

1) CleanMac.app dosyasını Applications klasörüne sürükleyin.
2) İlk açılışta macOS uyarı verirse:
   - CleanMac-Root-CA.crt dosyasını çift tıklayın
   - Anahtar Zinciri Erişimi > Sistem > CleanMac Root CA
   - Güven > Kod imzalama için: Her Zaman Güven
   - CleanMac.app için Sağ tık > Aç > Aç
EOF
fi

hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_OUTPUT"

if [[ "${USE_DEVELOPER_ID:-0}" -eq 1 ]]; then
  NOTARY_PROFILE="${NOTARY_PROFILE:-CleanMac-Notary}"
  echo ">> Notarizasyon (${NOTARY_PROFILE})"
  xcrun notarytool submit "$DMG_OUTPUT" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_OUTPUT"
fi

echo ">> Hazır: $DMG_OUTPUT"
codesign -dv --verbose=4 "$APP_PATH" 2>&1 | grep -E "Authority|Identifier|TeamIdentifier|Signature"
