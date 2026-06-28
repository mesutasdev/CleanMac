#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CERT_DIR="$ROOT/build/certs"
KEY="$CERT_DIR/CleanMac-DeveloperID.key"
KEYCHAIN="${KEYCHAIN:-$HOME/Library/Keychains/login.keychain-db}"

CER="${1:-}"

if [[ -z "$CER" ]]; then
  CER="$(ls -t ~/Downloads/developerID_application*.cer ~/Downloads/DeveloperID*.cer 2>/dev/null | head -1 || true)"
fi

if [[ -z "$CER" || ! -f "$CER" ]]; then
  echo "Kullanım: $0 /path/to/developerID_application.cer"
  echo
  echo "Apple Developer portaldan indirdiğiniz .cer dosyasının yolunu verin."
  echo "CSR dosyası: $CERT_DIR/CleanMac-DeveloperID.csr"
  exit 1
fi

if [[ ! -f "$KEY" ]]; then
  echo "Hata: Private key bulunamadı: $KEY"
  echo "Önce: ./scripts/install-developer-id-cert.sh"
  exit 1
fi

echo ">> Sertifika kuruluyor: $CER"
security import "$CER" -k "$KEYCHAIN"
security import "$KEY" -k "$KEYCHAIN" -T /usr/bin/codesign -T /usr/bin/productbuild

echo
echo ">> Keychain'deki imzalama kimlikleri:"
security find-identity -v -p codesigning | grep -E "Developer ID Application|valid identities" || true

if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  echo
  echo "✓ Developer ID Application kuruldu."
  echo "Sonraki adım: ./scripts/setup-notary-credentials.sh"
else
  echo
  echo "Uyarı: Developer ID Application görünmüyor. .cer dosyasının doğru sertifika olduğundan emin olun."
  exit 1
fi
