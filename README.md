<p align="center">
  <img src="docs/app-icon.png" alt="Remind.me icon" width="128" height="128">
</p>

# Remind.me

Tiny, calm macOS app for short-lived tasks. Menu bar + Dock, pin on top, archives overnight, plain-JSON storage.

> macOS 14+ · SwiftUI

## Install

Download `Remind.me-<version>.dmg` from [Releases](../../releases), open it, drag **Remind.me** to `/Applications`.

First launch: right-click → **Open** (one-time Gatekeeper prompt), or:

```bash
xattr -d com.apple.quarantine "/Applications/Remind.me.app"
open "/Applications/Remind.me.app"
```

## Build from source

```bash
brew install xcodegen
git clone https://github.com/F-Olivieri/Remind.me.git
cd Remind.me
xcodegen generate
open RemindMe.xcodeproj
```

DMG: `./scripts/build-dmg.sh` → `dist/Remind.me-<version>.dmg`

## Data

Default: `~/Library/Application Support/Remind.me/RemindMe.json`. Change in *Settings → Database*.

## License

MIT — see [LICENSE](LICENSE).
