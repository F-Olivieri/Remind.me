# Remind.me

A tiny, calm macOS app for tracking short-lived tasks — closer to Stickies than
to a productivity suite. Lives in the menu bar **and** the Dock (you choose),
pins on top when you need it, archives completed tasks overnight, and stores
everything in a plain JSON file you control.

> macOS 14+ · Native SwiftUI · 340 pt popup · Light + Dark

---

## Features

- **Menu-bar popup** — click the `checklist` glyph to open a 340 pt popup.
- **Add fast** — text field at the bottom, ⏎ to add, ⇧⏎ for urgent.
- **Urgent pinning** — urgent tasks get a left bar + tint + warning glyph and
  float to the top. Toggle per task via the row's `⋯` menu.
- **Complete in place** — click the circle to strike through and gray out. The
  next day the task rolls into the Archive automatically.
- **Archive** — restore, delete, or clear. Retention is configurable
  (1 day / 30 days / Unlimited / Custom 1–365 days).
- **Pin on top** — pin button promotes the window to `.floating` level and
  joins all spaces. Pinning from the menu bar fades the popover out and the
  pinned window in.
- **Custom database location** — point the JSON file at any folder
  (e.g. iCloud Drive, Dropbox) via *Settings → Database → Change…*.
- **Show / hide Dock icon** — *Settings → General*.
- **Tooltips on every icon** — hover for a one-line explanation.
- **VoiceOver labels + WCAG AA contrast** in both appearances.

## Screenshots

> Drop your screenshots into `docs/screenshots/` and they'll render here on
> GitHub.

| Popup | Pinned window | Settings |
|---|---|---|
| ![popup](docs/screenshots/popup.png) | ![pinned](docs/screenshots/pinned.png) | ![settings](docs/screenshots/settings.png) |

## Data

Default location:
`~/Library/Application Support/Remind.me/RemindMe.json`

Change it in *Settings → Database → Change…*. The app moves the existing file
to the new folder; pointing two Macs at the same iCloud folder is the simplest
way to share a list.

---

## Install

### Option 1 — Download the DMG (recommended)

1. Go to [Releases](../../releases) and download `Remind.me-<version>.dmg`.
2. Open the DMG and drag **Remind.me** into `/Applications`.
3. First launch: macOS will warn that the app is from an unidentified
   developer. **Right-click → Open → Open**, or run once via Terminal:
   ```bash
   xattr -d com.apple.quarantine "/Applications/Remind.me.app"
   open "/Applications/Remind.me.app"
   ```
   This is a one-time prompt. See [Code signing & notarization](#code-signing--notarization)
   below for why this happens.

### Option 2 — Build from source

Requirements: macOS 14+ and Xcode 15+ (Command Line Tools alone are not enough
— Swift macOS app bundles need the full Xcode SDK).

```bash
# One-time
brew install xcodegen

git clone https://github.com/F-Olivieri/Remind.me.git
cd Remind.me
xcodegen generate           # builds RemindMe.xcodeproj from project.yml
open RemindMe.xcodeproj     # hit Run, or:

xcodebuild -project RemindMe.xcodeproj \
           -scheme RemindMe \
           -configuration Release \
           -derivedDataPath build build
open "build/Build/Products/Release/Remind.me.app"
```

### Option 3 — Build the DMG yourself

```bash
./scripts/build-dmg.sh
# → dist/Remind.me-<version>.dmg
```

---

## Code signing & notarization

Short version: **the app is ad-hoc signed**, which means it runs fine but
Gatekeeper will show a warning the first time you open the downloaded build.

| Distribution path | Cert needed | Notarize? | User experience |
|---|---|---|---|
| Build & run locally | none (ad-hoc) | no | Runs immediately. |
| Direct download (DMG) ad-hoc | none | no | One-time "unidentified developer" dialog; right-click → Open works around it. |
| Direct download (DMG) signed + notarized | Developer ID Application ($99/yr Apple Developer Program) | **yes**, via `notarytool` | Opens silently. Required for a clean experience on macOS 15+. |
| Mac App Store | Apple Distribution cert | App Store review | Best UX but App-Store-only restrictions apply. |

### Why we don't sign by default

A proper Developer ID release costs $99/yr (Apple Developer Program) and
requires a personal Apple ID to be tied to the build. For a free OSS tool this
isn't worth it; the right-click-to-open workaround is one click and only
needed once per machine.

### If you want to sign + notarize a fork

```bash
# 1. Sign with hardened runtime
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  --entitlements Remind.me.entitlements \
  "Remind.me.app"

# 2. Zip and submit to notarytool (needs an App-Specific Password)
ditto -c -k --keepParent "Remind.me.app" "Remind.me.zip"
xcrun notarytool submit "Remind.me.zip" \
  --apple-id you@example.com --team-id TEAMID --password app-specific-pw \
  --wait

# 3. Staple the ticket so Gatekeeper works offline
xcrun stapler staple "Remind.me.app"

# 4. Build the DMG from the stapled .app
./scripts/build-dmg.sh
xcrun stapler staple dist/Remind.me-*.dmg
```

The signing identity has to be **Developer ID Application** (not Mac
Developer / Apple Distribution) — anything else won't notarize as a
direct-distribution app.

---

## Project layout

```
Remind.me/
├── project.yml                 # xcodegen spec
├── Sources/RemindMe/
│   ├── RemindMeApp.swift        # @main, scenes, AppDelegate
│   ├── DesignTokens.swift       # Space / Radius / Motion / Color.rmUrgent
│   ├── Models/Task.swift        # RTask
│   ├── Store/
│   │   ├── TaskStore.swift      # JSON persistence, rollover, retention
│   │   └── AppSettings.swift    # @AppStorage-style settings + activation policy
│   └── Views/
│       ├── PopupView.swift
│       ├── TaskRow.swift
│       ├── AddTaskField.swift
│       ├── ArchiveView.swift
│       ├── SettingsView.swift
│       └── FloatingWindowController.swift   # PinController
└── Resources/
    ├── Info.plist
    └── Assets.xcassets/         # AppIcon, MenuBarGlyph
```

## Contributing

PRs welcome. Keep the philosophy in mind:

- **Calm, not a suite.** Tasks live for hours, not quarters.
- **Inherit the system.** Defer to `Color.accentColor`, `.regularMaterial`,
  `.separatorColor`. The only literal brand color is `Color.rmUrgent`.
- **Glanceable.** Urgency is signalled structurally (bar + glyph + tint), not
  by hue alone.

Before opening a PR, please run `xcodegen generate` if you've changed
`project.yml` or added new source files.

## License

MIT — see [LICENSE](LICENSE).
