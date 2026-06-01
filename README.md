# Remind.me

Tiny macOS menu-bar popup for tracking tasks.

## Features

- Click the menu-bar `checklist` icon to open the popup.
- Add a task; ⇧⏎ (or the warning-triangle button) marks it urgent (pinned to top).
- Click the circle to mark complete — it grays out and strikes through.
- The day after completion, tasks roll over into **Archive** (menu → Show Archive…). Archive lets you restore or delete.
- Click the pin icon to detach the popup as a persistent floating window. Click again (or close it) to hide.
- Right-side `…` menu on each row: pin urgent, edit, delete. Double-click a row title to rename inline.

## Data

JSON file at `~/Library/Application Support/Remind.me/data.json`.

## Build

Requires Xcode 15+, macOS 14+.

```bash
brew install xcodegen   # one-time
xcodegen generate
open RemindMe.xcodeproj
```

Hit Run. The app has `LSUIElement=true` so it lives in the menu bar with no Dock icon.
