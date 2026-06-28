#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CERT_DIR="$ROOT/build/certs"
CSR="$CERT_DIR/CleanMac-DeveloperID.csr"
KEY="$CERT_DIR/CleanMac-DeveloperID.key"

mkdir -p "$CERT_DIR"

if [[ ! -f "$CSR" ]]; then
  openssl genrsa -out "$KEY" 2048
  openssl req -new -key "$KEY" -out "$CSR" \
    -subj "/emailAddress=mesutasdev@gmail.com/CN=MESUT AS/O=MESUT AS/C=US"
fi

echo "CSR hazır: $CSR"
echo
echo "1) https://developer.apple.com/account/resources/certificates/add adresine gidin"
echo "2) 'Developer ID Application' seçin"
echo "3) CSR dosyasını yükleyin: $CSR"
echo "4) İndirilen .cer dosyasını kurun:"
echo "   ./scripts/import-developer-id-cert.sh ~/Downloads/developerID_application.cer"
echo "5) Notarizasyon kimlik bilgisi:"
echo "   ./scripts/setup-notary-credentials.sh"
echo "6) Notarize edilmiş DMG:"
echo "   ./scripts/build-dmg.sh"
echo
open "https://developer.apple.com/account/resources/certificates/add"
