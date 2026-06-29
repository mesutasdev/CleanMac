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
3. Kurulum uygulamasına çift tıkla (**CleanMac'i Kur** / **Install CleanMac**) **veya** \`${APP_NAME}.app\` dosyasını Applications'a sürükle

- **KURULUM.txt** — Türkçe kurulum adımları
- **INSTALL.txt** — English installation steps

Kurulum uygulamasının adı macOS sistem diline göre gösterilir.

**Gereksinim:** macOS 13.0 (Ventura) veya üzeri

Apple Developer ID ile imzalanmış ve notarize edilmiştir.

### Bu sürümde
- **Düzeltme:** İlk tarama ekranında ("Önbellekler taranıyor…") içeriğin dar dikey şerit olarak görünmesi
- **İyileştirme:** Tarama başlarken disk alanı kartı hemen gösteriliyor

### Destek

${SUPPORT_SECTION}
EOF
