#!/bin/bash
set -euo pipefail

PROFILE="${NOTARY_PROFILE:-CleanMac-Notary}"
TEAM_ID="${TEAM_ID:-477K4S3LV2}"
APPLE_ID="${APPLE_ID:-mesutasdev@gmail.com}"

echo "Apple notarizasyon kimlik bilgisi kurulumu"
echo "Profile: $PROFILE"
echo "Team ID: $TEAM_ID"
echo "Apple ID: $APPLE_ID"
echo
echo "App-specific password oluştur:"
echo "  https://appleid.apple.com → Sign-In and Security → App-Specific Passwords"
echo "  İsim önerisi: CleanMac Notary"
echo

if security find-generic-password -s "$PROFILE" >/dev/null 2>&1; then
  echo "Mevcut profil bulundu: $PROFILE"
  read -r -p "Üzerine yazılsın mı? [y/N] " overwrite
  if [[ "${overwrite,,}" != "y" ]]; then
    echo "İptal."
    exit 0
  fi
fi

read -r -s -p "App-specific password: " APP_PASSWORD
echo

xcrun notarytool store-credentials "$PROFILE" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_PASSWORD"

echo
echo "✓ Notary profili kaydedildi: $PROFILE"
echo "Test: xcrun notarytool history --keychain-profile $PROFILE"
echo "DMG:  ./scripts/build-dmg.sh"
