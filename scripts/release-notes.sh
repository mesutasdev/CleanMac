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
3. **\`CleanMac'i Kur.app\`** dosyasına çift tıkla — kurar ve otomatik açar

Manuel kurulum: CleanMac'i kapat → \`${APP_NAME}.app\` dosyasını Applications'a sürükle → aç

**Gereksinim:** macOS 13.0 (Ventura) veya üzeri

Apple Developer ID ile imzalanmış ve notarize edilmiştir.

### Bu sürümde
- **`CleanMac'i Kur.app`**: DMG'den tek tıkla kurulum, kurulum sonrası otomatik açılış
- Açılışta ana pencere otomatik gösterilir
- Sidebar'da **CleanMac Hakkında** butonu
- Destek bilgileri: [Buy Me a Coffee](https://buymeacoffee.com/mesutasdevw), EnPara IBAN (Mesut As)
- Geliştirici linkleri: [mesutas.com](https://mesutas.com) | [TechAs.co](https://techas.co)
EOF
