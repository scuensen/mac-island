# Claude Island

> Claude AI direkt in der Mac-Notch — schwebendes AI-Widget für macOS

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/Lizenz-MIT-green)

## ⬇️ Download

**[→ Neueste Version herunterladen](../../releases/latest)**

### Installation
1. `ClaudeIsland.dmg` herunterladen
2. DMG öffnen → App nach `/Programme` ziehen
3. Beim ersten Start: **Rechtsklick → Öffnen** (einmalig für Gatekeeper-Bypass)
4. API-Key unter **Einstellungen** (`⌘,` oder Menüleiste) eintragen

---

## Features

| Feature | Details |
|---|---|
| 🧠 Floating Island | Schwebendes Widget im Notch-Bereich |
| ⚡ Schnell | Klick → Frage → Antwort, ohne App-Wechsel |
| 🎛 Modellwahl | Haiku / Sonnet / Opus wählbar |
| 📊 Live-Stats | Token-Verbrauch & API Rate Limits in Echtzeit |
| 🔄 Auto-Schließen | Konfigurierbarer Timer (5 / 10 / 30s) |
| 🌡 Parameter | Temperature & Max Tokens einstellbar |
| 🔒 Privat | API-Key nur lokal gespeichert |

## Voraussetzungen

- macOS 13 Ventura oder neuer
- MacBook (alle Modelle, besonders schön mit Notch)
- [Claude API-Key](https://console.anthropic.com/) von Anthropic

## Selbst bauen

```bash
git clone https://github.com/DEIN-USERNAME/claude-island
cd claude-island
brew install xcodegen
xcodegen generate
open ClaudeIsland.xcodeproj  # in Xcode öffnen
```

Oder DMG bauen:
```bash
./build.sh
```

## Release erstellen

```bash
git tag v1.0.1
git push origin v1.0.1
# → GitHub Actions baut automatisch DMG + erstellt Release
```

## Lizenz

MIT — mach damit was du willst.
