#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}Claude Island — Installer${NC}"
echo "────────────────────────────"
echo ""

# Download
echo -e "${BLUE}▶ Herunterladen...${NC}"
curl -L --progress-bar \
  "https://github.com/scuensen/mac-island/releases/latest/download/ClaudeIsland.dmg" \
  -o /tmp/ClaudeIsland.dmg

# Mount
echo -e "${BLUE}▶ Installieren...${NC}"
hdiutil attach /tmp/ClaudeIsland.dmg -mountpoint /tmp/ClaudeIslandDMG -quiet -nobrowse

# Copy to Applications
rm -rf "/Applications/Claude Island.app" 2>/dev/null || true
cp -r "/tmp/ClaudeIslandDMG/ClaudeIsland.app" "/Applications/"

# Remove Gatekeeper quarantine
xattr -dr com.apple.quarantine "/Applications/ClaudeIsland.app" 2>/dev/null || true

# Cleanup
hdiutil detach /tmp/ClaudeIslandDMG -quiet
rm /tmp/ClaudeIsland.dmg

echo ""
echo -e "${GREEN}✓ Claude Island wurde installiert!${NC}"
echo ""
echo "  Starte die App mit:"
echo -e "  ${BOLD}open /Applications/ClaudeIsland.app${NC}"
echo ""

# Launch
open "/Applications/ClaudeIsland.app"
