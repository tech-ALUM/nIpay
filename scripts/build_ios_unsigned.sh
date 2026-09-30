#!/usr/bin/env bash
# Build dell'ipa iOS senza firma. Unica fonte di verità per questo processo:
# usato sia in locale sia dalla CI (.github/workflows/ios.yml), per non
# rischiare che i due si disallineino nel tempo.
#
# Richiede Xcode. Per installare l'ipa risultante su un iPhone serve
# rifirmarla con sideloader-cli (vedi CLAUDE.md).
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

flutter pub get
flutter gen-l10n
flutter build ios --release --no-codesign

rm -rf Payload nipay-unsigned.ipa
mkdir -p Payload
cp -r build/ios/iphoneos/Runner.app Payload/
zip -qr nipay-unsigned.ipa Payload
rm -rf Payload

echo "Creato: nipay-unsigned.ipa"
