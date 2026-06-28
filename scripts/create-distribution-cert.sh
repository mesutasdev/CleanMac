#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CERT_DIR="$ROOT/build/certs"
CA_KEY="$CERT_DIR/CleanMac-CA.key"
CA_CRT="$CERT_DIR/CleanMac-CA.crt"
SIGN_KEY="$CERT_DIR/CleanMac-Codesign.key"
SIGN_CSR="$CERT_DIR/CleanMac-Codesign.csr"
SIGN_CRT="$CERT_DIR/CleanMac-Codesign.crt"
SIGN_P12="$CERT_DIR/CleanMac-Codesign.p12"
EXT_FILE="$CERT_DIR/codesign.ext"
IDENTITY="CleanMac Distribution"

mkdir -p "$CERT_DIR"

if [[ ! -f "$CA_CRT" ]]; then
  openssl genrsa -out "$CA_KEY" 4096
  openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days 3650 \
    -out "$CA_CRT" -subj "/CN=CleanMac Root CA/O=MESUT AS/C=US"
fi

if [[ ! -f "$SIGN_CRT" ]]; then
  cat > "$EXT_FILE" <<'EOF'
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF

  openssl genrsa -out "$SIGN_KEY" 2048
  openssl req -new -key "$SIGN_KEY" -out "$SIGN_CSR" \
    -subj "/CN=CleanMac Distribution/O=MESUT AS/C=US"
  openssl x509 -req -in "$SIGN_CSR" -CA "$CA_CRT" -CAkey "$CA_KEY" \
    -CAcreateserial -out "$SIGN_CRT" -days 825 -sha256 -extfile "$EXT_FILE"
fi

openssl pkcs12 -export -legacy -out "$SIGN_P12" -inkey "$SIGN_KEY" -in "$SIGN_CRT" \
  -certfile "$CA_CRT" -passout pass:cleanmac -name "$IDENTITY" >/dev/null

security import "$SIGN_P12" -k ~/Library/Keychains/login.keychain-db -P cleanmac \
  -T /usr/bin/codesign -T /usr/bin/security >/dev/null 2>&1 || true
security add-trusted-cert -d -r trustRoot -p codeSign -k ~/Library/Keychains/login.keychain-db "$CA_CRT" >/dev/null 2>&1 || true

echo "$IDENTITY"
