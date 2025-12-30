# IconSmith

**Batch file icon customization for macOS. Apply custom icons to files with drag-drop, presets, and AI generation.**

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014+-black?style=for-the-badge)]()
[![Swift](https://img.shields.io/badge/Swift-6-orange?style=for-the-badge)]()

## The Problem

macOS doesn't provide a way to bulk-customize file icons. If you want consistent, beautiful icons for your code files, configs, or project folders, you must:

1. Find or create icons manually
2. Open Get Info for each file (Cmd+I)
3. Copy/paste icons one at a time
4. Repeat dozens of times

This is tedious for developers, designers, and power users who care about visual organization.

## The Solution

IconSmith makes file icon customization fast through:

- **Batch operations** - Apply icons to hundreds of files at once
- **Finder integration** - Right-click any file to set its icon
- **Extension presets** - Map `.ts` to TypeScript icon, `.py` to Python, etc.
- **AI generation** - Generate custom icons with Gemini AI
- **Consistency detection** - Find and fix files with mismatched icons

## Features

### Folder Browser
Scan any folder and see all files grouped by extension. Detect inconsistencies (files with the same extension but different icons) and fix them with one click.

### Icon Library
Import icons from files or clipboard. Organize by category. Search and filter. Apply to files with drag-drop.

### Extension Presets
Create reusable mappings like "Code Files" that automatically apply the right icon to `.swift`, `.ts`, `.py`, `.rs`, and more. Apply presets to entire folders.

### AI Icon Generation
Generate custom icons with text prompts:
- "File icon for TypeScript with blue accents"
- "Minimal Docker whale icon"
- "Config file icon with gear symbol"

Choose from styles: macOS Big Sur, Flat, Outlined, or Glyph.

### Finder Extension
Right-click any file in Finder to:
- Set icon with IconSmith
- Remove custom icon
- Apply recent icons (quick access to last 5 used)

### Undo System
Every icon change is tracked. Undo with Opt+Cmd+Z to restore the original icon, even after restarting the app.

## Install

**Requirements:** macOS 14.0+ (Sonoma)

### From Source

```bash
git clone https://github.com/nicobailon/iconsmith.git
cd iconsmith
xcodegen generate
open IconSmith.xcodeproj
```

Then in Xcode:
1. Set your Development Team in Signing & Capabilities (both targets)
2. Build and Run (Cmd+R)

### Enable Finder Extension

After first launch:
1. Open **System Settings** > **Privacy & Security** > **Extensions** > **Finder Extensions**
2. Enable **IconSmithFinder**
3. Restart Finder if needed: `killall Finder`

## Usage

### Apply Icons to Files

**From Finder (recommended):**
1. Select files in Finder
2. Right-click > "Set Icon with IconSmith"
3. Choose an icon for each file extension
4. Click Apply

**From the app:**
1. Go to Folders > Add a folder
2. Select files in the file list
3. Click "Apply Icon to X files..."
4. Choose icons and apply

### Create a Preset

1. Go to Presets > New Preset
2. Add extension mappings (e.g., `swift` -> Swift icon)
3. Click "Apply to Folder..." to use it

### Generate Icons with AI

1. Go to Generate
2. Enter a prompt describing your icon
3. Select style and accent color
4. Click Generate
5. Save to library when satisfied

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+1 | Dashboard |
| Cmd+2 | Folders |
| Cmd+3 | Icon Library |
| Cmd+4 | Presets |
| Cmd+5 | Generate |
| Cmd+, | Settings |
| Opt+Cmd+Z | Undo last icon change |

## How It Works

IconSmith uses `NSWorkspace.setIcon()` to apply custom icons to individual files. This modifies the file's resource fork, which:

- Persists across renames and moves
- Survives app restarts
- Works on any file type
- Does NOT modify file contents

Icons applied by IconSmith are tracked via extended attributes (`com.iconsmith.applied`), making it easy to identify which files have custom icons.

## Data Storage

```
~/Library/Application Support/IconSmith/
├── Icons/
│   ├── imported/     # Icons imported from files
│   ├── generated/    # AI-generated icons
│   └── clipboard/    # Icons pasted from clipboard
├── library.json      # Icon metadata
├── folders.json      # Configured folders
├── presets.json      # Extension presets
├── activity.json     # Recent activity log
└── undo/
    ├── stack.json    # Undo history
    └── *.png         # Original icons for undo
```

## Limitations

- **iCloud files** - Custom icons may not sync between machines
- **Git** - Icons are stored in resource forks, not tracked by git
- **Sandboxed apps** - IconSmith is not sandboxed (required for `NSWorkspace.setIcon`)

## Development

### Project Structure

```
iconsmith/
├── project.yml              # XcodeGen config
├── IconSmith/
│   ├── App/                 # App entry, state management
│   ├── Models/              # Data models
│   ├── Services/            # Business logic
│   └── Views/               # SwiftUI views
├── IconSmithFinder/         # Finder Sync Extension
└── Shared/                  # Shared types between targets
```

### Build Commands

```bash
# Regenerate Xcode project after changing project.yml
xcodegen generate

# Open in Xcode
open IconSmith.xcodeproj
```

### Architecture

- **SwiftUI** with NavigationSplitView
- **Single AppState** pattern (similar to Default Opener)
- **@MainActor** isolation for thread safety
- **App Groups** for main app + Finder extension communication

## Roadmap

- [ ] Bundled icon pack (~50 curated icons)
- [ ] Watch folders (auto-apply icons to new files)
- [ ] Icon pack browser (vscode-icons, devicons)
- [ ] iCloud sync for icon library
- [ ] Notarization for distribution

## License

[Apache 2.0](LICENSE)
