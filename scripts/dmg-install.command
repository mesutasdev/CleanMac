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

# Yalnızca gerçek CleanMac.app sürecini bul (Cursor vb. eşleşmesin)
cleanmac_pids() {
  ps -ax -o pid=,command= | while read -r pid command; do
    case "$command" in
      */CleanMac.app/Contents/MacOS/CleanMac)
        echo "$pid"
        ;;
    esac
  done
}

cleanmac_is_running() {
  [[ -n "$(cleanmac_pids)" ]]
}

request_graceful_quit() {
  if command -v swift >/dev/null 2>&1; then
    swift -e 'import Foundation; CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFNotificationName("com.cleanmac.app.installQuit" as CFString), nil, nil, true)' 2>/dev/null || true
  fi
  osascript -e "tell application id \"${BUNDLE_ID}\" to quit" 2>/dev/null || true
  osascript -e 'tell application "CleanMac" to quit' 2>/dev/null || true
}

kill_cleanmac_processes() {
  local pid
  while read -r pid; do
    [[ -n "$pid" ]] || continue
    kill -TERM "$pid" 2>/dev/null || true
  done < <(cleanmac_pids)
  sleep 0.5
  while read -r pid; do
    [[ -n "$pid" ]] || continue
    kill -KILL "$pid" 2>/dev/null || true
  done < <(cleanmac_pids)
}

quit_cleanmac() {
  request_graceful_quit
  sleep 1.5

  local attempt
  for attempt in {1..20}; do
    cleanmac_is_running || return 0
    kill_cleanmac_processes
    sleep 0.25
  done

  if cleanmac_is_running; then
    osascript -e 'display alert "CleanMac kapatılamadı" message "⌘⌥Esc ile CleanMac'"'"'i zorla kapatın, sonra bu scripti tekrar çalıştırın." as critical'
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
open "$TARGET"

osascript -e 'display notification "CleanMac başarıyla kuruldu." with title "CleanMac Kurulum"' 2>/dev/null || true
exit 0
