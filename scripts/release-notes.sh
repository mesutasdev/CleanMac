#!/bin/bash
# Standart GitHub Release notları — publish-github-release.sh tarafından kullanılır.
# Kullanım: ./scripts/release-notes.sh 1.0.13

VERSION="${1:?Sürüm gerekli, örn: 1.0.13}"
APP_NAME="CleanMac"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUPPORT_SECTION="$(cat "$ROOT/scripts/support-section.md")"

cat <<EOF
## ${APP_NAME} ${VERSION}

Geliştiriciler için Mac disk temizleyici — Xcode, Flutter, npm, Gradle cache ve daha fazlası.

### Kurulum
1. \`${APP_NAME}-${VERSION}.dmg\` dosyasını indir
2. DMG'yi aç
3. **CleanMac'i Kur.app** dosyasına çift tıkla — kurar ve otomatik açar

Manuel kurulum: CleanMac'i kapat → \`${APP_NAME}.app\` dosyasını Applications'a sürükle → aç

**Gereksinim:** macOS 13.0 (Ventura) veya üzeri

Apple Developer ID ile imzalanmış ve notarize edilmiştir.

### Bu sürümde
- **Yeni:** Uygulama açılışında otomatik güncelleme kontrolü — tek tıkla indirip kurar
- Hakkında ekranından manuel "Güncellemeleri Denetle"
- Menü çubuğunda güncelleme varsa hızlı erişim

### Destek

${SUPPORT_SECTION}
EOF
