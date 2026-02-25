# 🧙 Snape - A Severus Snippet Manager for macOS

Handle your snippets with Severus precision.


## Features

- ⚡ Quick index selection (a-z, A-Z)
- 🔍 Real-time filtering with `/`
- 📁 Folder-based snippet grouping with separators
- 👀 Preview popup on hover and keyboard navigation
- 📋 Automatic clipboard copy with visual confirmation
- 🎨 Light/Dark/System theme support
- 🖱️ Opens at cursor position
- 💾 Remembers window size
- 🚪 Click outside to close

## 📖 Philosophy

Snape follows the **KISS** principle — *Keep It Simple, Severus* 🧙.

- Minimal UI, instant access
- Zero learning curve: open, pick, done
- Plain text storage for easy syncing and versioning
- Integrates with your existing workflow, not the other way around
- No accounts, no cloud, no nonsense

## Requirements

- macOS 13.0 (Ventura) or later

## Installation

### Homebrew

```bash
brew tap rgcr/formulae
brew install --cask snape
```

### Or Download Release

1. Download [Snape-2.0.0-macos.dmg](https://github.com/rgcr/snape/releases/download/v2.0.0/Snape-2.0.0-macos.dmg) from `Releases`
2. Open the DMG and drag `Snape.app` to `/Applications`
3. First launch: Right-click → Open (to bypass Gatekeeper)


## Hotkey Integration

- Snape works best when bound to a global hotkey.
- The app opens at your cursor position, you select a snippet, and it's copied to your clipboard.

### macOS Shortcuts (Native)

1. Open **Automator** → New → **Quick Action**
2. Add "Run Shell Script" action
3. Script: `open -a Snape`
4. Save as "Launch Snape"
5. Go to **System Settings** → **Keyboard** → **Keyboard Shortcuts** → **Services**
6. Find "Launch Snape" → Assign shortcut (e.g., `Cmd+Option+S`)

### Hammerspoon

```lua
-- In ~/.hammerspoon/init.lua:
hs.hotkey.bind({"cmd", "alt"}, "s", function()
    hs.application.launchOrFocus("Snape")
end)
```

### skhd

```bash
# In ~/.config/skhd/skhdrc:
cmd + alt - s : open -a Snape
```

### Raycast

Create a Quicklink with `open -a Snape` and assign a hotkey.

## Keyboard Shortcuts

### Normal Mode

| Key | Action |
|-----|--------|
| `↑` `↓` | Navigate snippets |
| `Enter` | Select snippet and copy to clipboard |
| `a-z` `A-Z` | Quick selection by index |
| `/` | Enter filter mode |
| `?` | Show about dialog |
| `Esc` | Quit |

### Filter Mode

| Key | Action |
|-----|--------|
| Type | Filter snippets by name or content |
| `Backspace` | Delete last character |
| `↑` `↓` | Navigate filtered list |
| `Enter` | Select snippet |
| `Esc` | Exit filter mode |

## Snippets Directory

Snippets are stored in: `~/.config/snape/`

Each file is a snippet. The filename (without extension) becomes the snippet name.

### Folder Structure

Use folders to organize snippets into groups:

```
~/.config/snape/
├── readme.txt              # Ungrouped (shown first)
├── 01-aws/                 # Group: "aws"
│   ├── 01-get-account.txt
│   └── 02-list-buckets.txt
├── 02-linux/               # Group: "linux"
│   ├── 01-find-files.txt
│   └── 02-disk-usage.txt
└── scripts/                # Group: "scripts" (no prefix)
    └── backup.txt
```

**Ordering:**
- **Folders** become section separators in the UI
- **Numeric prefix** (`01-`, `02-`) controls display order
- Prefixes are **stripped from display** (e.g., `01-aws` shows as "aws")
- **Ungrouped files** (in root) appear first
- Files within folders are also sorted by name/prefix

### Default Snippets

On first launch, if no snippets exist, sample snippets are created:
- `hello.txt` – "Hello, World!"
- `greeting.txt` – Friendly greeting
- `hello-world.go` – Hello World in Go

## Settings

Click the ⚙️ gear icon to access settings:

- **Theme**: System / Light / Dark

Window size is saved automatically when you resize.

## Acknowledgments

- Inspired by the template system of AutoHotkey’s `CL3` utility

## Contributing

1. Fork the repo
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push the branch: `git push origin my-new-feature`
5. Open a Pull Request 🚀
