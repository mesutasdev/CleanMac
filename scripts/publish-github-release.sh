#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="CleanMac"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' CleanMac/Info.plist)"
TAG="v${VERSION}"
DMG="$ROOT/build/${APP_NAME}-${VERSION}.dmg"
REPO="${GITHUB_REPO:-mesutasdev/CleanMac}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI gerekli: brew install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub'a giriş yapın:"
  gh auth login
fi

if [[ ! -f "$DMG" ]]; then
  echo "DMG bulunamadı. Önce: ./scripts/build-dmg.sh"
  exit 1
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  git init
  git branch -M main
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create "$REPO" --public --source=. --remote=origin --description "Xcode & Flutter geliştiricileri için macOS disk temizleyici" --push
else
  git push -u origin main
fi

gh release create "$TAG" "$DMG" \
  --title "${APP_NAME} ${VERSION}" \
  --notes "$("$ROOT/scripts/release-notes.sh" "$VERSION")"

echo ">> Release hazır: https://github.com/${REPO}/releases/tag/${TAG}"
