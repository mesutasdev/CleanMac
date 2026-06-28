#!/bin/bash
# Standart GitHub Release notları — publish-github-release.sh tarafından kullanılır.
# Kullanım: ./scripts/release-notes.sh 1.0.13

VERSION="${1:?Sürüm gerekli, örn: 1.0.13}"
APP_NAME="CleanMac"

cat <<EOF
## ${APP_NAME} ${VERSION}

Geliştiriciler için Mac disk temizleyici — Xcode, Flutter, npm, Gradle cache ve daha fazlası.

### Kurulum
1. \`${APP_NAME}-${VERSION}.dmg\` dosyasını indir
2. DMG'yi aç
3. Açık CleanMac varsa menü çubuğundan **CleanMac'den Çık** de
4. \`${APP_NAME}.app\` dosyasını **Applications** klasörüne sürükle
5. Uygulamayı aç

**Gereksinim:** macOS 13.0 (Ventura) veya üzeri

Apple Developer ID ile imzalanmış ve notarize edilmiştir.

### Bu sürümde
- Sidebar'da **CleanMac Hakkında** butonu
- Destek bilgileri: [Buy Me a Coffee](https://buymeacoffee.com/mesutasdevw), EnPara IBAN (Mesut As)
- Geliştirici linkleri: [mesutas.com](https://mesutas.com) | [TechAs.co](https://techas.co)
EOF
