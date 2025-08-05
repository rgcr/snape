
# 🧙 Snape - A Severus Snippet Manager

Handle your snippets with Severus precision.

## ✨ Features

- Quick index selection (a-z, A-Z)
- Real-time filtering with `/`
- Cross-platform: macOS, Windows, Linux
- File-based storage in `~/.snape/`
- Automatic clipboard copy on selection
- Open snippets folder from the interface

## 🚀 Installation

### Quick Install (Recommended)

Use the install script to download, build, and install Snape:

  `curl -fsSL https://raw.githubusercontent.com/rgcr/snape/main/install.sh | bash`

```bash
Install options:

  ./install.sh           # Install to /usr/local/bin (requires sudo)
  ./install.sh --local   # Install to ~/.local/bin (no sudo)
  ./install.sh --help    # Show options
```

**Requirements**:

- Go 1.19 or later
- Git

### Manual Build
```bash
  git clone https://github.com/rgcr/snape.git
  cd snape
  go build -o snape
```

## 🧩 Hotkey Integration

Snape works best when bound to a hotkey using your favorite keybinding tool.

### macOS - Hammerspoon

```bash
# In ~/.hammerspoon/init.lua:

hs.hotkey.bind({"cmd", "shift"}, "s", function()
    hs.task.new("/usr/local/bin/snape", nil, nil, {}):start()
end)
```

### macOS - skhd

```
# In ~/.config/skhd/skhdrc or ~/.skhdrc:

cmd + shift - s : /usr/local/bin/snape
```

### Linux - i3wm

```bash
# In ~/.i3/config:

bindsym $mod+s exec /usr/local/bin/snape
```

### Windows - AutoHotkey
```
# In your autohotkey script

# ctrl + alt + s
^!s::Run C:\Path\to\snape.exe
```

### Others

- Alfred (macOS): Create a workflow to run `/usr/local/bin/snape`

## 🖥️ Usage

Launch Snape from terminal or hotkey:

```bash
  snape                   # Default window size
  snape --verbose         # Verbose output
  snape --width-size 350 --height-size 500  # Custom window size

  snape --help            # Show help
```

## ⌨️ Keyboard Shortcuts

### Normal Mode
- ↑↓ : Navigate
- Enter : Select snippet and copy
- a-z / A-Z : Quick index selection
- / : Enter filter mode
- ? : Show about dialog
- Esc : Quit

### Filter Mode
- Type : Filter by keyword
- Backspace : Delete last char
- ↑↓ : Navigate filtered list
- Enter : Select snippet
- Esc : Exit filter mode

## 📂 Snippets Directory

Snippets live in: `~/.snape/`

Each file = one snippet.

```bash
Example:
  ~/.snape/
  ├── hello.txt
  ├── email-template.md
  ├── sql-queries.sql
  └── git-commands.sh
```

### Default Snippets (First Launch)

- `hello.txt` – “Hello, World!”
- `greeting.txt` – friendly greeting message
- `hello-world.go` – Hello World in `go`

## 🔨 Building

Requirements:

- `Go` `1.19+`
- `Fyne` and dependencies

Build:

   `go build -o snape`

## 🤝 Contributing

1. Fork repo
2. Create branch: `git checkout -b feature/amazing-feature`
3. Commit: `git commit -m 'Add amazing feature'`
4. Push: `git push origin feature/amazing-feature`
5. Open Pull Request

## License

MIT License – See `LICENSE` file.

## 🙏 Acknowledgments

- Powered by [Fyne](https://fyne.io/)
- Inspired by the template system of AutoHotkey’s `CL3` utility
- Named after Severus Snape for his precision and discipline
