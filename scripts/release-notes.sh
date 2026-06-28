#!/bin/bash
# Standart GitHub Release notları — publish-github-release.sh tarafından kullanılır.
# Kullanım: ./scripts/release-notes.sh 1.0.8

VERSION="${1:?Sürüm gerekli, örn: 1.0.8}"
APP_NAME="CleanMac"

cat <<EOF
## ${APP_NAME} ${VERSION}

Geliştiriciler için Mac disk temizleyici — Xcode, Flutter, npm, Gradle cache ve daha fazlası.

### Kurulum
1. \`${APP_NAME}-${VERSION}.dmg\` dosyasını indir
2. DMG'yi aç
3. \`${APP_NAME}.app\` dosyasını **Applications** klasörüne sürükle (mevcut sürümün üzerine yaz)
4. Uygulamayı aç

> Eski sürüm açıksa yeni sürüm başlarken otomatik kapanır — elle kapatmana gerek yok.

**Gereksinim:** macOS 13.0 (Ventura) veya üzeri

Apple Developer ID ile imzalanmış ve notarize edilmiştir.
EOF
