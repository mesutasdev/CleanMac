#!/bin/bash
# DMG içinden çalışır: açık CleanMac'i kapatır, Applications'a kurar, yeni sürümü açar.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/CleanMac.app"
TARGET="/Applications/CleanMac.app"
BUNDLE_ID="com.cleanmac.app"

if [[ ! -d "$APP" ]]; then
  osascript -e 'display alert "CleanMac.app bulunamadı" message "Bu script DMG içinden çalıştırılmalı." as critical'
  exit 1
fi

cleanmac_is_running() {
  pgrep -f "Contents/MacOS/CleanMac" >/dev/null 2>&1
}

quit_cleanmac() {
  # 1) Nazik kapatma
  osascript -e "tell application id \"${BUNDLE_ID}\" to quit" 2>/dev/null || true
  osascript -e 'tell application "CleanMac" to quit' 2>/dev/null || true
  sleep 1

  # 2) SIGTERM
  local attempt
  for attempt in {1..25}; do
    cleanmac_is_running || return 0
    pkill -f "Contents/MacOS/CleanMac" 2>/dev/null || true
    sleep 0.2
  done

  # 3) SIGKILL
  pkill -9 -f "Contents/MacOS/CleanMac" 2>/dev/null || true
  sleep 0.5

  if cleanmac_is_running; then
    osascript -e 'display alert "CleanMac kapatılamadı" message "Menü çubuğundan CleanMac'"'"'den Çık deyin, sonra bu scripti tekrar çalıştırın." as critical'
    exit 1
  fi
}

echo "▶ CleanMac kapatılıyor..."
quit_cleanmac
echo "   ✓ Kapatıldı"

echo "▶ CleanMac kuruluyor..."
rm -rf "$TARGET"
ditto "$APP" "$TARGET"
xattr -cr "$TARGET" 2>/dev/null || true
echo "   ✓ Kuruldu"

echo "▶ CleanMac açılıyor..."
sleep 0.5
open -n "$TARGET"

osascript -e 'display notification "CleanMac başarıyla kuruldu." with title "CleanMac Kurulum"' 2>/dev/null || true
exit 0
