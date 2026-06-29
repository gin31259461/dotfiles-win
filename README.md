# Windows Dotfiles

Personal Windows dotfiles managed with a bare Git repository and a small
companion CLI named Homebase.

This repository is rooted at `$HOME`, with Git metadata stored in
`~/.dotfiles`. Only selected configuration files are tracked; the rest of the
home directory stays outside the project.

> [!IMPORTANT]
> This is a home-directory work tree. Use the bare Git command form shown
> below, or the `dot` alias from the PowerShell profile, so Git does not treat
> unrelated personal files as project files.

## What is included

- Shell: `.pwsh/profile.ps1`, `.starship/starship.toml`, `.vimrc`
- Editor and terminal: `.config/nvim`, `.config/wezterm`,
  `.config/vscode-nvim`
- Homebase config: `.config/homebase/**`
- Windows apps: `.config/visual-studio/**`, `.config/ssms/**`,
  `.config/opencode/opencode.jsonc`
- Agent tooling: `.codex/agents/**`, `.agents/**`, `AGENTS.md`
- Git config: `.gitconfig`, `.gitattributes`, `.gitignore`, `.gitmodules`,
  `.dotfiles-repo`

The Neovim and WezTerm configs are Git submodules:

```powershell
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" `
  submodule update --init --recursive
```

## Prerequisites

- Windows with PowerShell.
- Git.
- Homebase built or installed at `~/.local/bin/hb.exe`.
- Optional tools installed by Homebase: PowerShell 7, PSReadLine,
  Node.js/pnpm, Starship, ripgrep, WezTerm, Lua, Neovim, tree-sitter, Notion,
  Obsidian, and FiraCode Nerd Font.

## Getting started

Clone or refresh the dotfiles through Homebase:

```powershell
hb bootstrap --install
```

For a non-interactive run:

```powershell
hb bootstrap --yes --install
```

Homebase reads the Windows platform config from
`.config/homebase/platforms/windows/config.toml`. The configured dotfiles
remote is remembered in `.dotfiles-repo`.

## Daily workflow

Use `dot` from the PowerShell profile:

```powershell
dot status
dot add .pwsh/profile.ps1
dot commit -m "update powershell profile"
dot push origin main
```

Or use the explicit bare Git form:

```powershell
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" status
```

To stage, commit, and push the configured sync paths in one step:

```powershell
hb sync -m "update dotfiles"
```

Commit without pushing:

```powershell
hb sync -m "update dotfiles" --no-push
```

## Homebase commands

Homebase is developed separately in `~/.local/lib/homebase` and built to `~/.local/bin/hb.exe`.

```powershell
hb help
hb config init
hb install
hb install --group cli --yes
hb install --all --yes
hb cleanup
hb cleanup --task npm-cache --yes
hb sync -m "update dotfiles"
```

Package groups live in `.config/homebase/platforms/windows/packages.d/*.toml`.
Cleanup tasks live in `.config/homebase/platforms/windows/cleanup.toml`.
Sync paths live in `.config/homebase/platforms/windows/sync.toml`.

## Developing Homebase

Homebase is a Go module at `~/.local/lib/homebase`.

```powershell
Set-Location "$HOME/.local/lib/homebase"
go test ./...
go vet ./...
go build -o "$HOME/.local/bin/hb.exe" ./cmd/hb
```

If `make` is available:

```powershell
make check
make build
make smoke
```

## Notes for editing

- Keep dotfiles changes scoped to tracked paths or paths listed in Homebase
  sync config.
- Treat `~/.local/lib/homebase` as its own Git repository.
- Keep PowerShell scripts compatible with Windows PowerShell 5.1 unless a file
  clearly targets PowerShell 7.
- Store `.ps1` files as UTF-8 with BOM.
- Do not commit generated package inventory files such as `winget_list.txt` or `scoop_list.txt`.
