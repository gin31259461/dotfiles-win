# Installer

Interactive TUI installer for the Windows dotfiles environment.

## Usage

```powershell
# Interactive — recommended
.\install.ps1

# Unattended — installs everything without the TUI
.\install.ps1 -Unattended

# Bootstrap a brand-new machine first
.\bootstrap.ps1

# System cleanup (interactive TUI)
.\cleanup.ps1

# System cleanup (unattended — runs all tasks)
.\cleanup.ps1 -Unattended
```

## TUI Controls

Both `install.ps1` and `cleanup.ps1` share the same keyboard-navigable menu
(provided by `lib/tui.ps1`):

| Key | Action |
|-----|--------|
| `↑` `↓` | Navigate |
| `Space` | Toggle item |
| `A` | Select all |
| `N` | Deselect all |
| `Enter` | Confirm / install selected |
| `Q` / `Esc` | Quit |

## Package Lists

Edit these files to customise what gets installed:

| File | Manager |
|------|---------|
| `packages/scoop.txt` | [Scoop](https://scoop.sh) |
| `packages/winget.txt` | [WinGet](https://github.com/microsoft/winget-cli) |

Lines starting with `#` are treated as comments.

## Fonts

Drop `.ttf` or `.otf` files into `fonts/` and the installer will copy them to
`%WINDIR%\Fonts` and register them in the user registry.

## Shared TUI Library

`lib/tui.ps1` is dot-sourced by all scripts.  It provides:

- **VT processing** — enables ANSI escape codes on all Windows PowerShell versions
- **Colour constants** — `$RED`, `$GRN`, `$YLW`, `$BLU`, `$CYN`, `$BOLD`, `$DIM`, `$RST`, etc.
- **Print helpers** — `die`, `ok`, `warn`, `note`, `step`, `section`
- **`Invoke-Confirm`** — yes/no prompt
- **`Invoke-Spin`** — spinner for slow operations
- **`Start-TuiMenu`** — full-screen keyboard menu (returns selected items or `$null` on cancel)
