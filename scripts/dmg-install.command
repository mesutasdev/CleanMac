#!/bin/bash
# DMG içinden çalışır: açık CleanMac'i kapatır, Applications'a kurar, yeni sürümü açar.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/CleanMac.app"
TARGET="/Applications/CleanMac.app"
APP_NAME="CleanMac"

if [[ ! -d "$APP" ]]; then
  osascript -e "display alert \"CleanMac.app bulunamadı\" message \"Bu script DMG içinden çalıştırılmalı.\" as critical"
  exit 1
fi

quit_cleanmac() {
  osascript -e "tell application \"${APP_NAME}\" to quit" 2>/dev/null || true

  local i
  for i in {1..20}; do
    pgrep -x "$APP_NAME" >/dev/null || return 0
    sleep 0.25
  done

  pkill -x "$APP_NAME" 2>/dev/null || true
  sleep 0.5

  if pgrep -x "$APP_NAME" >/dev/null; then
    pkill -9 -x "$APP_NAME" 2>/dev/null || true
    sleep 0.3
  fi
}

echo "▶ ${APP_NAME} kapatılıyor..."
quit_cleanmac

echo "▶ ${APP_NAME} kuruluyor..."
rm -rf "$TARGET"
ditto "$APP" "$TARGET"

echo "▶ ${APP_NAME} açılıyor..."
open "$TARGET"

osascript -e "display notification \"CleanMac başarıyla kuruldu.\" with title \"CleanMac Kurulum\"" 2>/dev/null || true

exit 0
