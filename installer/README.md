# Installer

Interactive TUI installer for the Windows dotfiles environment.

## Usage

```powershell
# Interactive — recommended
.\Install.ps1

# Unattended — installs everything without the TUI
.\Install.ps1 -Unattended

# Bootstrap a brand-new machine first
.\Bootstrap.ps1
```

## TUI Controls

| Key | Action |
|-----|--------|
| `↑` `↓` | Navigate |
| `Space` | Toggle item |
| `A` | Select all |
| `N` | Deselect all |
| `Enter` | Install selected |
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
