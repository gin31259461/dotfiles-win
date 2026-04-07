---
applyTo: 'dotfiles.ps1,installer/**,README.md,.pwsh/**,.starship/**'
description: 'Rules for managing this Windows bare-repo dotfiles setup'
---

# Dotfiles Management Instructions

## Overview

Dotfiles are managed with a **bare git repository** at `~/.dotfiles`.
The work tree is `$HOME` itself — config files live at their real paths with no symlinks required.
The `dot` alias (defined in `~/.pwsh/profile.ps1`) wraps `git` with the correct flags.

## Repository Layout

```
~/
├── .config/
│   ├── nvim/               # Neovim config      ← git submodule (gin31259461/nvchad)
│   ├── wezterm/            # WezTerm config      ← git submodule (gin31259461/wezterm)
│   ├── vscode-nvim/        # VSCode Neovim keybindings
│   ├── visual-studio/      # Visual Studio exported settings
│   └── ssms/               # SSMS settings
├── .pwsh/
│   └── profile.ps1         # PowerShell profile (aliased via $profile symlink)
├── .starship/
│   └── starship.toml       # Starship prompt config
├── .vimrc                  # Vim config
├── installer/
│   ├── Install.ps1         # Interactive TUI installer
│   ├── Bootstrap.ps1       # One-time new-machine bootstrap
│   ├── packages/
│   │   ├── scoop.txt       # Scoop package names (one per line, # = comment)
│   │   └── winget.txt      # Winget package IDs  (one per line, # = comment)
│   └── fonts/              # .ttf / .otf fonts installed to user fonts dir
├── dotfiles.ps1            # Sync helper: stage → commit → push
└── README.md
```

## The `dot` Command

Defined in `~/.pwsh/profile.ps1`:

```powershell
function Invoke-Dot {
    git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" @Args
}
New-Alias dot Invoke-Dot
```

Use exactly like `git`:

```powershell
dot status
dot diff
dot add .config/nvim
dot add .pwsh/profile.ps1
dot commit -m "update nvim"
dot push origin main
dot log --oneline -10
```

**Never run plain `git` from `$HOME`** for dotfiles — always use `dot`.

## Syncing Dotfiles

Use `dotfiles.ps1` to stage all tracked paths at once:

```powershell
# Default commit message
.\dotfiles.ps1

# Custom commit message
.\dotfiles.ps1 -Message "update starship config"

# Preview without committing
.\dotfiles.ps1 -DryRun
```

The tracked path list is the `$TrackedPaths` array inside `dotfiles.ps1`. When adding a new config directory to the repo, **add it to that array** so future syncs pick it up automatically.

## Adding a New Config to Track

```powershell
# 1. Stage the path
dot add .config/new-tool

# 2. Add it to $TrackedPaths in dotfiles.ps1
# 3. Commit
dot commit -m "track new-tool config"
dot push origin main
```

## Submodules

| Submodule | Local Path | Remote |
|-----------|-----------|--------|
| nvchad | `.config/nvim` | `git@github.com:gin31259461/nvchad.git` (branch: main) |
| wezterm | `.config/wezterm` | `git@github.com:gin31259461/wezterm.git` (branch: main) |

```powershell
# Init after bootstrapping
dot submodule update --init --recursive

# Update all submodules to latest
dot submodule update --remote --merge

# Sync .gitmodules → .git/config after editing .gitmodules
dot submodule sync --recursive
```

**Do not `dot add` inside a submodule directory** — manage submodule content via their own repos.

## PowerShell Profile

Source: `~/.pwsh/profile.ps1`  
Symlinked to: `$profile` (`~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`)

Key aliases and functions defined in the profile:

| Alias | Target | Purpose |
|-------|--------|---------|
| `dot` | `Invoke-Dot` | Bare-repo git for dotfiles |
| `v` | `nvim` | Neovim |
| `k` | `kubectl` | Kubernetes |
| `h` | `helm` | Helm |
| `g` | `Invoke-Goto` | Quick directory navigation |
| `kn` | `Set-KubeNamespace` | Switch kubectl namespace |

`Invoke-Goto` shortcuts: `pr` → `~/projects`, `bp` → `~/projects/boilerplates`, `cs` → `~/projects/cheat-sheets`

## Installer

### Install.ps1 — Interactive TUI

```powershell
.\installer\Install.ps1             # interactive
.\installer\Install.ps1 -Unattended # install everything silently
```

TUI controls: `↑↓` navigate, `Space` toggle, `A` select all, `N` deselect all, `Enter` install, `Q`/`Esc` quit.

Menu groups and their item IDs:

| Group | Item ID | What it installs |
|-------|---------|-----------------|
| Core | `core-scoop` | Scoop package manager |
| Core | `core-pwsh` | PowerShell 7+ via winget |
| Core | `core-psreadline` | PSReadLine module |
| Core | `core-node` | Node.js + pnpm |
| Scoop Packages | `scoop-<name>` | Each line in `packages/scoop.txt` |
| Winget Packages | `winget-<id>` | Each line in `packages/winget.txt` |
| Setup | `setup-fonts` | Fonts from `fonts/` → user fonts dir |
| Setup | `setup-profile` | Symlink `$profile` → `~/.pwsh/profile.ps1` |
| Setup | `setup-wezterm-ctx` | WezTerm folder context menu entry |
| Setup | `setup-win10-menu` | Restore Win10 classic right-click menu |

To **add a new installer item**, add a `New-MenuItem` call inside `Get-MenuItems` in `Install.ps1`.

### Bootstrap.ps1 — New Machine Setup

```powershell
.\installer\Bootstrap.ps1
.\installer\Bootstrap.ps1 -RepoUrl 'https://github.com/yourname/dotfiles-win.git'
```

Clones the bare repo to `~/.dotfiles`, robocopy's files to `$HOME`, sets `showUntrackedFiles no`.

## Package Lists

`installer/packages/scoop.txt` — one Scoop package name per line.  
`installer/packages/winget.txt` — one winget package ID per line (e.g. `Neovim.Neovim`).  
Lines starting with `#` are ignored.

```
# Example scoop.txt entry
wezterm-nightly

# Example winget.txt entry
Neovim.Neovim
```

## File Encoding

**All `.ps1` files must be saved as UTF-8 with BOM.** This is required for PowerShell 5.1 to correctly parse non-ASCII characters (Unicode icons in TUI, box-drawing chars, etc.).

To re-encode in PowerShell:

```powershell
$utf8bom = New-Object System.Text.UTF8Encoding $true
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($path, $content, $utf8bom)
```

## Common Tasks

### Sync all dotfiles
```powershell
cd ~; .\dotfiles.ps1
```

### Check dotfiles status
```powershell
dot status
```

### Edit PowerShell profile
```powershell
v ~/.pwsh/profile.ps1
# reload
. $profile
```

### Update starship config
```powershell
v ~/.starship/starship.toml
dot add .starship
dot commit -m "update starship"
```

### Add a scoop package to the installer
1. `scoop install <package>`
2. Add `<package>` to `~/installer/packages/scoop.txt`
3. Run `.\dotfiles.ps1 -Message "add <package> to scoop packages"`

### Add a winget package to the installer
1. Find the ID: `winget search <name>`
2. Add the ID to `~/installer/packages/winget.txt`
3. Run `.\dotfiles.ps1 -Message "add <package> to winget packages"`

### Restore Win10 classic context menu
```powershell
.\installer\Install.ps1
# select only "Win10 Context Menu" → Enter
```

To revert back to Win11 menu:
```powershell
Remove-Item -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -Recurse
```
