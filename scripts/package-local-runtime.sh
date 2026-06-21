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

BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
if [[ -z "$BREW_PREFIX" ]]; then
  echo "Homebrew-prefix kunde inte hittas." >&2
  exit 1
fi

copy_library_tree() {
  local binary="$1"
  local owner_kind="$2"
  local deps
  deps="$(otool -L "$binary" | tail -n +2 | awk '{print $1}' | grep "^$BREW_PREFIX/" || true)"

  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue
    local dep_name
    dep_name="$(basename "$dep")"
    local copied_dep="$PACKAGE_ROOT/lib/$dep_name"

    if [[ ! -f "$copied_dep" ]]; then
      cp "$dep" "$copied_dep"
      chmod u+w "$copied_dep"
      copy_library_tree "$copied_dep" "lib"
    fi

    if [[ "$owner_kind" == "bin" ]]; then
      install_name_tool -change "$dep" "@executable_path/../lib/$dep_name" "$binary" || true
    else
      install_name_tool -change "$dep" "@loader_path/$dep_name" "$binary" || true
    fi
  done <<< "$deps"
}

copy_library_tree "$PACKAGE_ROOT/bin/tesseract" "bin"

for lib in "$PACKAGE_ROOT"/lib/*; do
  [[ -f "$lib" ]] || continue
  chmod u+w "$lib"
  install_name_tool -id "@rpath/$(basename "$lib")" "$lib" || true
  copy_library_tree "$lib" "lib"
done

cat > "$PACKAGE_ROOT/README.txt" <<EOF
Anvisa Tesseract Runtime $VERSION ($ARCH)

Detta paket är avsett att laddas ner av Anvisa och installeras i Application Support.
Paketet innehåller Tesseract-motor och nödvändiga runtime-bibliotek.
Språkmodeller (.traineddata) laddas ner separat av Anvisa.
EOF

cat > "$PACKAGE_ROOT/licenses/NOTICE.txt" <<EOF
This package bundles Tesseract OCR and runtime libraries from Homebrew for use by Anvisa.

Tesseract OCR is licensed under Apache License 2.0.
Bundled dependencies may use their own open source licenses. Review the corresponding
Homebrew formulae and upstream projects before publishing a production release.
EOF

(
  cd "$BUILD_DIR"
  /usr/bin/ditto -c -k "AnvisaTesseractRuntime-macos-$ARCH" "$ZIP_PATH"
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
