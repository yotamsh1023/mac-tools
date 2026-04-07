# Mac Tools 🛠️

A collection of lightweight macOS menu bar apps built with Swift.

## Apps

### 📋 ClipBoard — Clipboard Manager
Saves your clipboard history with search, pinned items, and inline editing.

- **Hotkey:** `Cmd+Shift+V`
- History saved to SQLite (`~/.local/share/clipboard/clips.db`)
- Search, pin, edit, and copy from history
- Supports text, images, and files

### ⏱️ NudgeBar — Screen Time Tracker
Tracks how long you've been actively sitting at the computer. Reminds you to stretch every hour.

- Pauses automatically when idle (5+ min), screen locked, or sleeping
- Hourly popup with a funny message and stretch tip
- Reset session from menu bar

### 🌍 TranslateBar — Google Translate
Opens Google Translate in a small popup from the menu bar.

- **Hotkey:** `Cmd+Shift+T`
- Remembers your last used language pair
- Full keyboard support (Cmd+A, Cmd+C, Cmd+V)

### 🕐 WorldClock — Second Timezone
Shows a second timezone clock in the menu bar next to the system clock.

- Choose from 12 cities
- Toggle 12/24 hour format
- Toggle timezone label

---

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools

```bash
xcode-select --install
```

---

## Build & Run

Each app has its own folder. To build and run:

```bash
cd clipboard && make run
cd screentime-nudge && make run
cd translate-bar && make run
cd worldclock && make run
```

### Auto-start on login
```bash
make login-item
```

---

## First Launch (Gatekeeper)

Since the apps are not notarized, run this once before opening:

```bash
xattr -cr ClipBoard.app
```

Or right-click → Open on older macOS versions.

---

## Project Structure

```
mac-tools/
├── clipboard/          # ClipBoard — clipboard manager
├── screentime-nudge/   # NudgeBar — screen time tracker
├── translate-bar/      # TranslateBar — Google Translate popup
└── worldclock/         # WorldClock — second timezone clock
```

Each app follows the same structure:
```
app-name/
├── Package.swift
├── Makefile
├── Resources/Info.plist
└── Sources/
```
