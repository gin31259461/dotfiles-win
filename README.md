# Windows Dotfiles

Personal Windows dotfiles managed by Homebase and a bare Git repository.

This repository is the platform homepage for the environment: it documents what
is managed, how a new machine is brought online, and how changes are synced
without reviving the old installer workflow.

## Core Value

- Rebuild a Windows development shell from a repeatable Homebase workflow
- Keep dotfiles in their normal locations under `$HOME`
- Store Git metadata outside the work tree at `~/.dotfiles`
- Manage packages, cleanup tasks, and sync paths through Homebase TOML
- Keep editor, terminal, shell, prompt, and AI-assistant settings versioned
- Use submodules for larger external configs such as Neovim and WezTerm

Use this repository when setting up or maintaining this Windows workstation,
syncing personal dotfiles, or adjusting Homebase package and cleanup policy.

## Requirements

- Windows with PowerShell 5.1 or newer
- `winget` available in `PATH`
- Git for manual dotfiles operations
- Go 1.24.2 when rebuilding Homebase from source
- Network access to the dotfiles and Homebase repositories

Homebase installs or verifies most routine tooling during bootstrap and package
installation.

## Get Started

Run the Homebase Windows bootstrap from PowerShell:

```powershell
$repoUrl = "https://raw.githubusercontent.com/gin31259461/homebase"
irm "$repoUrl/main/bootstrap/windows.ps1" | iex
```

That script installs minimum dependencies, clones or updates Homebase, builds
`hb.exe`, adds `~/.local/bin` to the user `Path`, and runs:

```powershell
hb bootstrap
```

For unattended setup:

```powershell
$repoUrl = "https://raw.githubusercontent.com/gin31259461/homebase"
& ([scriptblock]::Create((irm "$repoUrl/main/bootstrap/windows.ps1"))) -Yes
```

To bootstrap and install selected package groups in one run:

```powershell
$repoUrl = "https://raw.githubusercontent.com/gin31259461/homebase"
& ([scriptblock]::Create((irm "$repoUrl/main/bootstrap/windows.ps1"))) `
  -Yes -Install
```

To use a fork or another dotfiles remote:

```powershell
$repoUrl = "https://raw.githubusercontent.com/gin31259461/homebase"
& ([scriptblock]::Create((irm "$repoUrl/main/bootstrap/windows.ps1"))) `
  -DotfilesRepo git@github.com:you/dotfiles-win.git
```

## Daily Workflow

Homebase is the preferred interface:

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
hb sync -m "chore: sync dotfiles" --no-push
```

Interactive commands use Bubble Tea selectors. Automation should pass `--yes`
with explicit `--group` or `--task` selections, or `--all`.

## Managed Files

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

Submodules:

| Name | Path | Repository |
| --- | --- | --- |
| nvchad-config | `.config/nvim` | `git@github.com:gin31259461/nvchad.git` |
| wezterm | `.config/wezterm` | `git@github.com:gin31259461/wezterm.git` |

Refresh submodules with:

```powershell
dot submodule update --init --recursive
```

## Homebase Layout

Homebase is installed separately from this dotfiles repository:

```text
~/.local/lib/homebase
~/.local/bin/hb.exe
```

Runtime Windows configuration:

```text
~/.config/homebase/platforms/windows/
~/.config/homebase/platforms/windows/packages.d/*.toml
```

This runtime directory controls the current machine and may contain local files
that are not tracked by the dotfiles repository.

Default Windows configuration source:

```text
~/.local/lib/homebase/config/platforms/windows/
~/.local/lib/homebase/config/platforms/windows/packages.d/*.toml
```

Current package groups:

| Group | Purpose |
| --- | --- |
| `core` | Scoop, PowerShell, PSReadLine, Node.js, and pnpm |
| `cli` | Starship, Neovim, ripgrep, WezTerm, and Lua |
| `apps` | Notion and Obsidian |
| `setup` | PowerShell profile and WezTerm context menu setup |
| `fonts` | `nerd-fonts` Scoop bucket and `FiraCode-NF` |
| `classic-menu` | Windows 10 classic context menu registry setup |

Use TOML for package changes. Do not recreate the removed `installer/`
workflow, old package text files, or bundled font directories.

## Dotfiles Git

The work tree is `$HOME`; the Git directory is `~/.dotfiles`.

The PowerShell profile defines `dot` as a wrapper around the bare repository:

```powershell
function Invoke-Dot {
  git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" @Args
}

New-Alias dot Invoke-Dot
```

Use `dot` like regular Git:

```powershell
dot status
dot add README.md AGENTS.md .pwsh/profile.ps1
dot commit -m "docs: update dotfiles docs"
dot push origin main
```

The preferred sync path is still Homebase:

```powershell
hb sync -m "chore: sync dotfiles"
```

## Manual Recovery

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

## Development

Most dotfiles changes are plain configuration edits. Homebase itself is a
separate Go repository at `~/.local/lib/homebase`.

When changing Homebase:

```powershell
Set-Location ~/.local/lib/homebase
gofmt -w cmd internal
go test ./...
go vet ./...
go build -o ~/.local/bin/hb.exe ./cmd/hb
```

After README changes in this repository, run:

```powershell
markdownlint-cli2 README.md AGENTS.md
```

## FAQ

### Where are dotfiles stored?

Files live in their normal locations under `$HOME`. Git metadata lives in the
bare repository at `~/.dotfiles`.

### What does `~/.dotfiles-repo` do?

It records the selected dotfiles remote. Homebase uses it when syncing and when
preserving fork choices across runs.

### Why not use the old installer directory?

Homebase replaced the old PowerShell installer scripts, package text files, and
bundled font directories. Bootstrap, package install, cleanup, and sync now live
behind `hb` and Homebase TOML.

### How do I add or remove packages?

Edit TOML under:

```text
~/.config/homebase/platforms/windows/packages.d/
```

If the change should become a default, update the matching file under:

```text
~/.local/lib/homebase/config/platforms/windows/packages.d/
```

### What if `hb` is not found?

Open a new terminal or confirm this directory is in the user `Path`:

```text
%USERPROFILE%\.local\bin
```

Rebuild Homebase if the binary is missing:

```powershell
Set-Location ~/.local/lib/homebase
go build -o ~/.local/bin/hb.exe ./cmd/hb
```

### How do I refresh missing Homebase config?

```powershell
hb config init
```

Use `--force` only when you intentionally want to refresh runtime config from
Homebase defaults.

## Contributing

Read `AGENTS.md` before changing files. It captures the automation boundaries,
encoding rules, verification commands, and repository split between dotfiles and
Homebase.

For bug reports, include:

- Windows version and PowerShell version
- The `hb` or `dot` command that failed
- Relevant flags and config paths
- Expected behavior and actual output
- Whether the change involved runtime config or Homebase defaults

For pull requests:

- Keep changes scoped to the affected dotfile or Homebase area
- Use Homebase TOML for package, cleanup, and sync policy
- Do not restore the removed `installer/` workflow
- Preserve PowerShell UTF-8 with BOM requirements for `.ps1` files
- Run the relevant verification commands before submitting

## Reference

- [Homebase](https://github.com/gin31259461/homebase)
- [A simpler way to manage your dotfiles](https://www.anand-iyer.com/blog/2018/a-simpler-way-to-manage-your-dotfiles/)
