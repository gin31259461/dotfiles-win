---
applyTo: '**'
description: 'Guidelines for managing this Windows bare-repo dotfiles setup.'
---

# Dotfiles Management Guidelines

## Overview

Dotfiles are managed with a **bare git repository** — no symlinks, no stow.
The working tree is `$HOME`; config files live at their real paths.

| Path | Purpose |
|---|---|
| `~/.dotfiles/` | Bare git repository |
| `~` | Working tree (all tracked files live here directly) |
| `~/.pwsh/profile.ps1` | PowerShell profile (symlinked to `$profile`) |
| `~/.starship/starship.toml` | Starship prompt config |
| `~/.config/nvim/` | Neovim config — git submodule (gin31259461/nvchad) |
| `~/.config/wezterm/` | WezTerm config — git submodule (gin31259461/wezterm) |
| `~/.config/vscode-nvim/` | VSCode Neovim extension keybindings |
| `~/.config/visual-studio/` | Visual Studio exported settings |
| `~/.config/ssms/` | SQL Server Management Studio settings |
| `~/installer/` | Install.ps1 TUI, Bootstrap.ps1, package lists, fonts |
| `~/dotfiles.ps1` | Sync helper: stage → commit → push |
| `~/.github/` | Copilot instructions |

**Always use the `dot` alias** for git operations — never run plain `git` in `$HOME`:

```powershell
# dot is defined in ~/.pwsh/profile.ps1
function Invoke-Dot {
    git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" @Args
}
New-Alias dot Invoke-Dot
```

---

## Git Operations

```powershell
# Status / diff
dot status
dot diff

# Stage and commit a specific file
dot add .config/nvim
dot add .pwsh/profile.ps1
dot commit -m "feat(nvim): update keymaps"

# Push
dot push origin main

# Recent history
dot log --oneline -10
```

---

## Syncing Dotfiles

`dotfiles.ps1` stages every tracked path, commits, and pushes in one shot.

```powershell
# Default message ("sync dotfiles")
.\dotfiles.ps1

# Custom message (preferred)
.\dotfiles.ps1 -Message "chore: update starship config"

# Dry-run — preview what would be staged without committing
.\dotfiles.ps1 -DryRun
```

The set of staged paths is the `$TrackedPaths` array in `dotfiles.ps1`:

```
README.md  .gitmodules  .gitignore  .github  dotfiles.ps1
installer  .config/wezterm  .config/visual-studio  .config/vscode-nvim
.config/ssms  .config/nvim  .pwsh  .starship  .vimrc
```

When adding a new config, add it to `$TrackedPaths` so future syncs pick it up.

---

## Adding a New Config to Track

```powershell
# 1. Stage the path
dot add .config/new-tool

# 2. Add the path to $TrackedPaths in ~/dotfiles.ps1

# 3. Commit and push
dot commit -m "chore: track new-tool config"
dot push origin main
```

---

## Submodules

| Submodule | Local Path | Remote |
|---|---|---|
| nvchad | `.config/nvim` | `git@github.com:gin31259461/nvchad.git` (main) |
| wezterm | `.config/wezterm` | `git@github.com:gin31259461/wezterm.git` (main) |

```powershell
# Init after bootstrapping
dot submodule update --init --recursive

# Update submodules to their latest upstream commit
dot submodule update --remote --merge

# Sync .gitmodules → .git/config after editing .gitmodules
dot submodule sync --recursive
```

**Do not `dot add` inside a submodule directory** — manage submodule content via their own repos.

---

## PowerShell Profile

Source: `~/.pwsh/profile.ps1` — symlinked to `$profile` by `installer/Install.ps1`.

Key aliases and functions:

| Alias | Function | Purpose |
|---|---|---|
| `dot` | `Invoke-Dot` | Bare-repo git for dotfiles |
| `v` | `nvim` | Neovim |
| `k` | `kubectl` | Kubernetes |
| `h` | `helm` | Helm |
| `g` | `Invoke-Goto` | Quick directory navigation |
| `kn` | `Set-KubeNamespace` | Switch kubectl namespace |

`Invoke-Goto` shortcuts: `pr` → `~/projects`, `bp` → `~/projects/boilerplates`, `cs` → `~/projects/cheat-sheets`

`Set-KubeNamespace`: accepts `default` or `d` as shorthand for the default namespace.

PSReadLine is configured with history-based prediction and Vim-style `Ctrl+h`/`Ctrl+k` navigation.

Starship is loaded with: `$ENV:STARSHIP_CONFIG = "$HOME\.starship\starship.toml"`

To edit and reload the profile:

```powershell
v ~/.pwsh/profile.ps1
. $profile
```

---

## Installer

### Install.ps1 — Interactive TUI

```powershell
.\installer\Install.ps1              # interactive
.\installer\Install.ps1 -Unattended  # install everything silently
```

TUI controls: `↑↓` navigate · `Space` toggle · `A` select all · `N` deselect all · `Enter` install · `Q`/`Esc` quit.

| Group | Item ID | What it installs |
|---|---|---|
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

To add a new installer item, add a `New-MenuItem` call inside `Get-MenuItems` in `Install.ps1`.

### Bootstrap.ps1 — New Machine Setup

```powershell
.\installer\Bootstrap.ps1
.\installer\Bootstrap.ps1 -RepoUrl 'https://github.com/yourname/dotfiles-win.git'
```

Clones the bare repo to `~/.dotfiles`, robocopy's files to `$HOME`, sets `showUntrackedFiles no`.

---

## Package Lists

`installer/packages/scoop.txt` — one Scoop package name per line.  
`installer/packages/winget.txt` — one winget package ID per line.  
Lines starting with `#` are ignored.

Current winget packages: `Starship.Starship`, `Neovim.Neovim`, `BurntSushi.ripgrep.MSVC`, `Notion.Notion`, `Obsidian.Obsidian`, `wez.wezterm`

To add a scoop package:
1. `scoop install <package>`
2. Add `<package>` to `~/installer/packages/scoop.txt`
3. `.\dotfiles.ps1 -Message "chore: add <package> to scoop packages"`

To add a winget package:
1. `winget search <name>` to find the ID
2. Add the ID to `~/installer/packages/winget.txt`
3. `.\dotfiles.ps1 -Message "chore: add <package> to winget packages"`

---

## File Encoding

**All `.ps1` files must be saved as UTF-8 with BOM.** PowerShell 5.1 requires this to correctly parse non-ASCII characters (Unicode icons in TUI, box-drawing chars, etc.).

```powershell
$utf8bom = New-Object System.Text.UTF8Encoding $true
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($path, $content, $utf8bom)
```

---

## Commit Style

Use **Conventional Commits** for all `dot commit` messages. No co-author trailers.

```
<type>(<scope>): <subject>
```

- `<scope>` is optional; omit it for broad changes
- Subject line: lowercase, imperative mood, no period, ≤72 chars

| Type | When to use |
|---|---|
| `feat` | New feature or config option |
| `fix` | Bug fix or broken behaviour |
| `refactor` | Restructure without behaviour change |
| `docs` | README, instructions, comments |
| `chore` | Package list updates, housekeeping |
| `style` | Formatting, whitespace, cosmetic |
| `revert` | Revert a previous commit |

```
feat(installer): add neovim to winget packages
fix(profile): correct goto shortcut for projects dir
refactor: reorganise installer into packages/ subdir
docs: update README new-machine setup steps
chore: add ripgrep to winget packages
style: align installer menu columns
```

- **No co-author trailers** — never append `Co-authored-by:` lines
- Use `dot commit` not `git commit` when committing dotfiles
- Prefer atomic commits (one logical change per commit)
- Pass a descriptive `-Message` to `dotfiles.ps1` — avoid generic `"sync dotfiles"`
