#!/bin/bash
set -e

echo "=== Claude Island → GitHub ==="
echo ""
echo "Schritt 1: GitHub Login (Browser öffnet sich)..."
gh auth login --web --git-protocol https

echo ""
echo "Schritt 2: Repo erstellen & pushen..."
gh repo create claude-island \
  --public \
  --description "Claude AI direkt in der Mac-Notch — schwebendes AI-Widget für macOS" \
  --source=. \
  --remote=origin \
  --push

echo ""
echo "Schritt 3: Ersten Release erstellen..."
git tag v1.0.0
git push origin v1.0.0

echo ""
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "╔══════════════════════════════════════════════════╗"
echo "║  ✓ Fertig!                                       ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "  Repo:     https://github.com/$REPO"
echo "  Releases: https://github.com/$REPO/releases"
echo ""
echo "  GitHub Actions baut jetzt automatisch das DMG."
echo "  In ~5 Minuten ist der Download-Link live."
echo ""
echo "  Zum Teilen: https://github.com/$REPO/releases/latest"
