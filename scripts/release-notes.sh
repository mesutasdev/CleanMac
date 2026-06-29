#!/bin/bash
# Standart GitHub Release notları — publish-github-release.sh tarafından kullanılır.
# Kullanım: ./scripts/release-notes.sh 1.0.13

VERSION="${1:?Sürüm gerekli, örn: 1.0.13}"
APP_NAME="CleanMac"
REPO="${GITHUB_REPO:-mesutasdev/CleanMac}"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${DMG_NAME}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUPPORT_SECTION="$(cat "$ROOT/scripts/support-section.md")"

cat <<EOF
## ${APP_NAME} ${VERSION}

Geliştiriciler için Mac disk temizleyici — Xcode, Flutter, npm, Gradle cache ve daha fazlası.

### Kurulum
1. [${DMG_NAME}](${DOWNLOAD_URL}) dosyasını indir
2. DMG'yi aç
3. **Install CleanMac.app** / **CleanMac'i Kur.app**'e çift tıkla **veya** \`${APP_NAME}.app\` dosyasını Applications'a sürükle

Kurulum adımları DMG içinde **INSTALL.txt** / **KURULUM.txt** dosyasında Türkçe ve English yan yana yer alır. Kurulum uygulamasının adı macOS diline göre gösterilir.

**Gereksinim:** macOS 13.0 (Ventura) veya üzeri

Apple Developer ID ile imzalanmış ve notarize edilmiştir.

### Bu sürümde
- **İyileştirme:** Kurulum uygulaması adı macOS diline göre (Install CleanMac / CleanMac'i Kur)
- **İyileştirme:** INSTALL.txt / KURULUM.txt — çift tıkla-kur-aç ve sürükle-bırak yolları TR/EN yan yana
- **İyileştirme:** Kurulum uygulaması CleanMac roket ikonunu kullanıyor

### Destek

${SUPPORT_SECTION}
EOF
