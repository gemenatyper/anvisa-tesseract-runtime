#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-1.0.0}"
ARCH="$(uname -m)"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
PACKAGE_ROOT="$BUILD_DIR/AnvisaTesseractRuntime-macos-$ARCH"
ZIP_PATH="$BUILD_DIR/AnvisaTesseractRuntime-macos-$ARCH.zip"

TESSERACT_BIN="$(command -v tesseract || true)"
if [[ -z "$TESSERACT_BIN" ]]; then
  echo "tesseract hittades inte. Installera först en lokal runtime som kan paketeras." >&2
  exit 1
fi

rm -rf "$PACKAGE_ROOT" "$ZIP_PATH"
mkdir -p "$PACKAGE_ROOT/bin" "$PACKAGE_ROOT/lib" "$PACKAGE_ROOT/licenses"

cp "$TESSERACT_BIN" "$PACKAGE_ROOT/bin/tesseract"
chmod +x "$PACKAGE_ROOT/bin/tesseract"

cat > "$PACKAGE_ROOT/README.txt" <<EOF
Anvisa Tesseract Runtime $VERSION ($ARCH)

Detta paket är avsett att laddas ner av Anvisa och installeras i Application Support.
Paketet innehåller Tesseract-motor och nödvändiga runtime-bibliotek.
Språkmodeller (.traineddata) laddas ner separat av Anvisa.
EOF

cat > "$PACKAGE_ROOT/licenses/NOTICE.txt" <<EOF
TODO: Lägg in licenstexter för Tesseract, Leptonica och övriga bundlade beroenden.
Tesseract: Apache License 2.0.
EOF

echo "OBS: Detta script kopierar just nu bara tesseract-binären."
echo "Nästa steg är att samla dylib-beroenden med otool och justera install names med install_name_tool."

(
  cd "$BUILD_DIR"
  /usr/bin/ditto -c -k --keepParent "AnvisaTesseractRuntime-macos-$ARCH" "$ZIP_PATH"
)

SHA256="$(/usr/bin/shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
BYTE_COUNT="$(/usr/bin/stat -f '%z' "$ZIP_PATH")"

cat > "$BUILD_DIR/manifest.$ARCH.json" <<EOF
{
  "version": "$VERSION",
  "packages": [
    {
      "architecture": "$ARCH",
      "url": "https://github.com/gemenatyper/anvisa-tesseract-runtime/releases/download/v$VERSION/AnvisaTesseractRuntime-macos-$ARCH.zip",
      "sha256": "$SHA256",
      "byteCount": $BYTE_COUNT
    }
  ]
}
EOF

echo "Skapade:"
echo "  $ZIP_PATH"
echo "  $BUILD_DIR/manifest.$ARCH.json"
