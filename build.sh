#!/bin/bash
set -e

VERSION="1.0.0"
SCHEME="ClaudeIsland"
PROJECT="ClaudeIsland.xcodeproj"
BUILD_DIR="$(pwd)/build"
APP_NAME="Claude Island"
DMG_NAME="ClaudeIsland-${VERSION}.dmg"

echo "=== Claude Island Build ==="
echo ""

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/app"

# Build Release
echo "► Kompiliere Release…"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_HARDENED_RUNTIME=NO \
  build 2>&1 | grep -E "^(error:|warning: |Build succeeded|Build FAILED)" || true

# Finde .app
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "ClaudeIsland.app" \
  -not -path "*/PlugIns/*" -not -path "*/PackageFrameworks/*" 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
  echo "✗ .app nicht gefunden. Build fehlgeschlagen."
  exit 1
fi

echo "✓ Gebaut: $APP_PATH"

# Ad-hoc signieren
echo "► Signiere (ad-hoc)…"
codesign --deep --force --sign - "$APP_PATH"
echo "✓ Signiert"

# In build/ kopieren
cp -r "$APP_PATH" "$BUILD_DIR/app/"

# DMG erstellen
echo "► Erstelle DMG…"

if command -v create-dmg &>/dev/null; then
  create-dmg \
    --volname "$APP_NAME" \
    --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" 2>/dev/null || true \
    --window-size 540 360 \
    --icon-size 120 \
    --icon "ClaudeIsland.app" 140 180 \
    --app-drop-link 400 180 \
    --background /dev/null \
    "$BUILD_DIR/$DMG_NAME" \
    "$BUILD_DIR/app/" 2>/dev/null || simple_dmg
else
  simple_dmg
fi

function simple_dmg() {
  echo "  (create-dmg nicht gefunden, erstelle einfaches DMG)"
  TMP_DMG="$BUILD_DIR/dmg_src"
  rm -rf "$TMP_DMG"; mkdir "$TMP_DMG"
  cp -r "$BUILD_DIR/app/ClaudeIsland.app" "$TMP_DMG/"
  ln -sf /Applications "$TMP_DMG/Applications"
  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$TMP_DMG" \
    -ov -format UDZO \
    "$BUILD_DIR/$DMG_NAME" > /dev/null
  rm -rf "$TMP_DMG"
}

simple_dmg 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✓ Fertig!                                   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  DMG: build/$DMG_NAME"
echo ""
echo "  Zum Verteilen:"
echo "  • DMG per AirDrop, Mail oder WeTransfer schicken"
echo "  • Empfänger öffnet DMG → zieht App nach Programme"
echo "  • Beim ersten Start: Rechtsklick → Öffnen"
echo "    (macOS Gatekeeper-Warnung, da keine Apple-Signatur)"
echo ""
echo "  Für vertrauenswürdige Verteilung ohne Warnung:"
echo "  → Apple Developer Program ($99/Jahr) + Notarisierung"
echo ""

# DMG direkt öffnen?
read -p "DMG jetzt öffnen? [j/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[JjYy]$ ]]; then
  open "$BUILD_DIR/$DMG_NAME"
fi
