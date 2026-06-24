# Windows Dotfiles

Personal Windows dotfiles managed with a bare Git repository at `~/.dotfiles`.
Files live in their normal locations under `$HOME`; Git metadata lives outside
the working tree.

Machine bootstrap, package installation, cleanup, and sync are handled by
[Homebase](https://github.com/gin31259461/homebase). This repository stores the
dotfiles themselves.

## Layout

```text
~/
|-- .config/
|   |-- nvim/             # Neovim config, submodule
|   |-- wezterm/          # WezTerm config, submodule
|   |-- vscode-nvim/      # VSCode Neovim settings
|   |-- visual-studio/    # Visual Studio settings
|   |-- ssms/             # SQL Server Management Studio settings
|   `-- opencode/         # opencode config
|-- .pwsh/profile.ps1     # PowerShell profile
|-- .starship/starship.toml
|-- .vimrc
|-- .gitconfig
|-- .dotfiles-repo        # remembered dotfiles remote
|-- AGENTS.md
`-- README.md
```

Homebase is installed separately at:

```text
~/.local/lib/homebase
~/.local/bin/hb.exe
```

## New Machine Setup

Run the Homebase Windows bootstrap from PowerShell:

```powershell
$repoUrl = "https://raw.githubusercontent.com/gin31259461/homebase"
irm "$repoUrl/main/bootstrap/windows.ps1" | iex
```

That script installs the minimal Homebase dependencies, builds `hb.exe`, adds
`~/.local/bin` to the user `Path`, then runs:

```powershell
hb bootstrap
```

To run without prompts:

```powershell
$repoUrl = "https://raw.githubusercontent.com/gin31259461/homebase"
& ([scriptblock]::Create((irm "$repoUrl/main/bootstrap/windows.ps1"))) -Yes
```

To bootstrap from a fork or another dotfiles remote:

```powershell
$repoUrl = "https://raw.githubusercontent.com/gin31259461/homebase"
& ([scriptblock]::Create((irm "$repoUrl/main/bootstrap/windows.ps1"))) `
  -DotfilesRepo git@github.com:you/dotfiles-win.git
```

To bootstrap and install all selected Homebase package groups:

```powershell
$repoUrl = "https://raw.githubusercontent.com/gin31259461/homebase"
& ([scriptblock]::Create((irm "$repoUrl/main/bootstrap/windows.ps1"))) `
  -Yes -Install
```

## Dot Command

The PowerShell profile defines a `dot` alias for the bare repository:

```powershell
function Invoke-Dot {
  git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" @Args
}

New-Alias dot Invoke-Dot
```

Use `dot` like `git`:

```powershell
dot status
dot add .config/nvim
dot commit -m "update nvim config"
dot push origin main
```

## Homebase Commands

Homebase is the preferred interface for routine maintenance:

```powershell
hb bootstrap
hb install
hb cleanup
hb sync
```

Common non-interactive examples:

```powershell
hb install --group core --group cli --yes
hb install --group fonts --yes
hb cleanup --task scoop-cache --task temp-files --yes
hb sync -m "chore: sync dotfiles"
```

## Packages

Windows packages are configured in Homebase TOML, not in this dotfiles repo.

Runtime config:

```text
~/.config/homebase/platforms/windows/packages.d/*.toml
```

Default config source:

```text
~/.local/lib/homebase/config/platforms/windows/packages.d/*.toml
```

Current Windows groups include:

- `core`: Scoop, PowerShell, PSReadLine, Node.js, and pnpm
- `cli`: Starship, Neovim, ripgrep, WezTerm, and Lua
- `apps`: Notion and Obsidian
- `setup`: PowerShell profile and WezTerm context menu setup
- `fonts`: `nerd-fonts` Scoop bucket and `FiraCode-NF`
- `classic-menu`: Windows 10 classic context menu registry setup

Run the interactive installer:

```powershell
hb install
```

## Syncing Changes

Use Homebase to stage the configured dotfile paths, commit, and push:

```powershell
hb sync
hb sync -m "chore: sync dotfiles"
hb sync -m "chore: sync dotfiles" --no-push
```

The tracked paths are configured in:

```text
~/.config/homebase/platforms/windows/sync.toml
```

Current sync groups cover:

- core repository files: `.dotfiles-repo`, `.gitmodules`, `.gitignore`,
  `.gitattributes`, `.gitconfig`, `AGENTS.md`, `README.md`
- config paths: `.config/*`, `.pwsh`, `.starship`, `.vimrc`, `.agents`

## Manual Setup

Use this only when Homebase is unavailable:

```powershell
git clone --separate-git-dir="$HOME/.dotfiles" `
  git@github.com:gin31259461/dotfiles-win.git `
  "$env:TEMP\dotfiles-tmp"

robocopy "$env:TEMP\dotfiles-tmp" $HOME /E /XD .git | Out-Null
Remove-Item "$env:TEMP\dotfiles-tmp" -Recurse -Force

git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" `
  config --local status.showUntrackedFiles no

git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" `
  submodule update --init --recursive
```

## Fork Workflow

Homebase stores the selected dotfiles remote in `~/.dotfiles-repo`.

Set a fork during bootstrap:

```powershell
hb bootstrap --repo git@github.com:you/dotfiles-win.git
```

Or edit `~/.dotfiles-repo` directly:

```text
git@github.com:you/dotfiles-win.git
```

Then commit the updated memory file:

```powershell
hb sync -m "chore: set dotfiles remote"
```

## Cleanup

Run the interactive cleanup selector:

```powershell
hb cleanup
```

Run selected tasks:

```powershell
hb cleanup --task scoop-cache --task temp-files --yes
hb cleanup --all --yes
```

Windows cleanup tasks are configured in:

```text
~/.config/homebase/platforms/windows/cleanup.toml
```

## Submodules

| Name | Path | Repository |
| --- | --- | --- |
| nvchad-config | `.config/nvim` | `git@github.com:gin31259461/nvchad.git` |
| wezterm | `.config/wezterm` | `git@github.com:gin31259461/wezterm.git` |

Initialize or refresh submodules:

```powershell
dot submodule update --init --recursive
```

## Troubleshooting

If `hb` is not found, open a new terminal or confirm this path is in the user
`Path`:

```text
%USERPROFILE%\.local\bin
```

Rebuild Homebase:

```powershell
Set-Location ~/.local/lib/homebase
go build -o ~/.local/bin/hb.exe ./cmd/hb
```

If Homebase config is missing or stale:

```powershell
hb config init
```

## Reference

- [A simpler way to manage your dotfiles](https://www.anand-iyer.com/blog/2018/a-simpler-way-to-manage-your-dotfiles/)
