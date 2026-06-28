#!/bin/bash
# Sessiz kurulum uygulaması oluşturur: CleanMac'i Kur.app (terminal yok)
set -euo pipefail

STAGING="${1:?Staging klasörü gerekli}"
SIGN_IDENTITY="${2:-}"

INSTALLER="$STAGING/CleanMac'i Kur.app"
MACOS="$INSTALLER/Contents/MacOS"
RESOURCES="$INSTALLER/Contents/Resources"
APP_SOURCE="$STAGING/CleanMac.app"

[[ -d "$APP_SOURCE" ]] || { echo "CleanMac.app staging'de bulunamadı: $APP_SOURCE" >&2; exit 1; }

APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_SOURCE/Contents/Info.plist")"
APP_BUILD="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$APP_SOURCE/Contents/Info.plist")"

mkdir -p "$MACOS" "$RESOURCES"
ditto "$APP_SOURCE" "$RESOURCES/CleanMac.app"
cp "$(cd "$(dirname "$0")" && pwd)/dmg-install.sh" "$MACOS/install"
chmod +x "$MACOS/install"

/usr/libexec/PlistBuddy -c "Add :CFBundleDevelopmentRegion string tr" "$MACOS/../Info.plist" 2>/dev/null || true
cat > "$INSTALLER/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>tr</string>
	<key>CFBundleExecutable</key>
	<string>install</string>
	<key>CFBundleIdentifier</key>
	<string>com.cleanmac.app.installer</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>CleanMac'i Kur</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${APP_VERSION}</string>
	<key>CFBundleVersion</key>
	<string>${APP_BUILD}</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>LSUIElement</key>
	<true/>
</dict>
</plist>
EOF

if [[ -n "$SIGN_IDENTITY" ]]; then
  /usr/bin/codesign --force --deep --sign "$SIGN_IDENTITY" --options runtime --timestamp "$INSTALLER"
fi

echo ">> Kurulum uygulaması: $INSTALLER"
