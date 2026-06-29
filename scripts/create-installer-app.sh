#!/bin/bash
# Sessiz kurulum uygulaması: Install CleanMac.app (TR: CleanMac'i Kur)
set -euo pipefail

STAGING="${1:?Staging klasörü gerekli}"
SIGN_IDENTITY="${2:-}"

INSTALLER="$STAGING/Install CleanMac.app"
MACOS="$INSTALLER/Contents/MacOS"
RESOURCES="$INSTALLER/Contents/Resources"
APP_SOURCE="$STAGING/CleanMac.app"

[[ -d "$APP_SOURCE" ]] || { echo "CleanMac.app staging'de bulunamadı: $APP_SOURCE" >&2; exit 1; }

APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_SOURCE/Contents/Info.plist")"
APP_BUILD="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$APP_SOURCE/Contents/Info.plist")"

mkdir -p "$MACOS" "$RESOURCES/en.lproj" "$RESOURCES/tr.lproj"
ditto "$APP_SOURCE" "$RESOURCES/CleanMac.app"
cp "$(cd "$(dirname "$0")" && pwd)/dmg-install.sh" "$MACOS/install"
chmod +x "$MACOS/install"

APP_ICON="$APP_SOURCE/Contents/Resources/AppIcon.icns"
if [[ -f "$APP_ICON" ]]; then
  cp "$APP_ICON" "$RESOURCES/AppIcon.icns"
fi

cat > "$RESOURCES/en.lproj/InfoPlist.strings" <<'EOF'
CFBundleDisplayName = "Install CleanMac";
CFBundleName = "Install CleanMac";
EOF

cat > "$RESOURCES/tr.lproj/InfoPlist.strings" <<'EOF'
CFBundleDisplayName = "CleanMac'i Kur";
CFBundleName = "CleanMac'i Kur";
EOF

cat > "$INSTALLER/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>install</string>
	<key>CFBundleIdentifier</key>
	<string>com.cleanmac.app.installer</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Install CleanMac</string>
	<key>CFBundleDisplayName</key>
	<string>Install CleanMac</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIconName</key>
	<string>AppIcon</string>
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
