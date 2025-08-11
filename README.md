
# 🧙 Snape - A Severus Snippet Manager

Handle your snippets with Severus precision.

## Features

<table>
  <tr>
    <td valign="top" width="60%">
<ul>
  <li> Quick index selection (a-z, A-Z)</li>
  <li> Real-time filtering with <code>/</code></li>
  <li> Cross-platform: macOS, Windows, Linux</li>
  <li> File-based storage in <code>~/.snape/</code></li>
  <li> Automatic clipboard copy on selection</li>
  <li> Open snippets folder from the interface</li>
</ul>
</td>
  <td valign="top" width="40%">
  <img width="300" height="400" alt="Snape Screenshot" src="https://github.com/user-attachments/assets/ebe6905c-d7fd-4b17-bc47-58359ee6b13a" />
  </td>
</tr>
</table>


## 📖 Philosophy

Snape follows the **KISS** principle — *Keep It Simple, Severus* 🧙.

-  Minimal UI, instant access
-  Zero learning curve: open, pick, done
-  Plain text storage for easy syncing and versioning
-  Integrates with your existing workflow, not the other way around
-  No accounts, no cloud, no nonsense



## Installation

### Using Homebrew

`brew install rgcr/formulae/snape`

### Using the Install script

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

## Hotkey Integration

Snape works best when bound to a hotkey using your favorite keybinding tool.
> Change the path to where `snape` is installed.

#### macOS - Hammerspoon

```bash
# In ~/.hammerspoon/init.lua:

hs.hotkey.bind({"cmd", "alt"}, "s", function()
    hs.task.new("/usr/local/bin/snape", nil, nil, {}):start()
end)
```

#### macOS - skhd

```
# In ~/.config/skhd/skhdrc or ~/.skhdrc:

cmd + alt - s : /usr/local/bin/snape
```

#### Linux - i3wm

```bash
# In ~/.i3/config:

bindsym $mod+s exec /usr/local/bin/snape
```

#### Windows - AutoHotkey
```
# In your autohotkey script

# ctrl + alt + s
^!s::Run C:\Path\to\snape.exe
```

#### Others

- Alfred (macOS): Create a workflow to run `/usr/local/bin/snape`

## Usage

Launch Snape from terminal or hotkey:

```bash
  snape                   # Default window size
  snape --verbose         # Verbose output
  snape --width-size 350 --height-size 500  # Custom window size

  snape --help            # Show help
```

## Keyboard Shortcuts

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

##  Snippets Directory

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


## Contributing

1. Fork repo
2. Create branch: `git checkout -b my-feature`
3. Commit: `git commit -m 'Add amazing feature'`
4. Push: `git push origin my-feature`
5. Open Pull Request


## Acknowledgments

- Powered by [Fyne](https://fyne.io/)
- Inspired by the template system of AutoHotkey’s `CL3` utility
