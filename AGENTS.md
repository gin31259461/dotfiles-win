# AGENTS.md

## Project Overview

This work tree is a Windows dotfiles repository rooted at `$HOME`. It uses a
bare Git repository at `~/.dotfiles` and tracks only selected configuration
files under the home directory.

Homebase is the companion setup/sync CLI. Its source is a separate Go
repository at `~/.local/lib/homebase`, and its binary is expected at
`~/.local/bin/hb.exe`.

Key tracked areas:

- PowerShell profile: `.pwsh/profile.ps1`
- Homebase config: `.config/homebase/**`
- Editor and terminal config: `.config/nvim`, `.config/wezterm`, `.config/vscode-nvim/**`
- Prompt and Git config: `.starship/starship.toml`, `.gitconfig`,
  `.gitattributes`, `.gitignore`, `.gitmodules`
- App settings: `.config/visual-studio/**`, `.config/ssms/**`,
  `.config/opencode/opencode.jsonc`
- Agent config and skills: `.codex/agents/**`, `.agents/**`

## Repository Boundaries

- The repository root is the real home directory, not a normal project folder.
- Do not scan or mutate unrelated personal files under `$HOME`.
- Treat untracked home-directory files as out of scope unless the user
  explicitly names them.
- Treat `.local/lib/homebase` as a separate Git repository.
- Keep edits scoped to requested dotfiles, Homebase config, or Homebase source.
- The Neovim and WezTerm directories are Git submodules.

Use this form for dotfiles Git operations:

```powershell
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" status
```

The PowerShell profile defines the equivalent `dot` alias:

```powershell
dot status
dot add .pwsh/profile.ps1
dot commit -m "update powershell profile"
```

## Standard Workflow

1. Read this file, `README.md`, and files directly related to the task.
2. Check dotfiles status before editing:

   ```powershell
   git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" status --short
   ```

3. If touching Homebase source, also check:

   ```powershell
   git -C "$HOME/.local/lib/homebase" status --short
   ```

4. Inspect only tracked dotfiles or explicitly relevant files.
5. Make the smallest scoped change that satisfies the task.
6. Run the smallest meaningful verification.
7. Report commands run and any verification skipped.

## Setup and Development Commands

Initialize Homebase config for the current platform:

```powershell
hb config init
```

Bootstrap dotfiles and optionally install packages:

```powershell
hb bootstrap
hb bootstrap --yes --install
```

Install configured Windows package groups:

```powershell
hb install
hb install --group cli --yes
hb install --all --yes
```

Run cleanup tasks:

```powershell
hb cleanup
hb cleanup --task npm-cache --yes
```

Sync configured dotfiles paths:

```powershell
hb sync -m "update dotfiles"
hb sync -m "update dotfiles" --no-push
```

Update submodules:

```powershell
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" `
  submodule update --init --recursive
```

## Homebase Development

Homebase is a Go module in `~/.local/lib/homebase`.

Common commands:

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

Homebase command surface:

```text
hb bootstrap [--yes] [--repo <repo>] [--install]
hb install   [--group <key>] [--all] [--yes] [--no-setup]
hb cleanup   [--task <key>] [--all] [--yes]
hb sync      [-m <message>] [--no-push]
hb config init [-f|--force]
```

## Testing and Verification

- For dotfile-only documentation changes, run a bare Git status check and
  inspect the rendered Markdown if practical.
- For Homebase config changes, run `hb help` and the relevant non-destructive
  command path when possible.
- For Homebase source changes, run `go test ./...` from `~/.local/lib/homebase`.
- For broad Homebase changes, run `go vet ./...` and
  `go build -o "$HOME/.local/bin/hb.exe" ./cmd/hb`.
- Avoid running package installation, cleanup, or destructive system commands
  unless the user explicitly requested them.

## Code and File Style

- Prefer existing patterns and naming.
- Keep Markdown factual, concise, and command-oriented.
- Keep `.toml` config sorted by the existing package-file order where possible.
- Keep Lua config style consistent with `.config/vscode-nvim`.
- Keep Go code formatted with `gofmt`.
- Do not introduce unrelated formatting churn.

## PowerShell Encoding

All `.ps1` files must be UTF-8 with BOM for Windows PowerShell 5.1
compatibility.

When creating or rewriting PowerShell files, use:

```powershell
[System.IO.File]::WriteAllText(
  $path,
  $content,
  [System.Text.UTF8Encoding]::new($true)
)
```

After editing a `.ps1` file, verify the BOM if the write path might have
removed it.

## Security and Safety

- Do not expose or modify secrets, tokens, SSH keys, browser data, or unrelated
  app data in `$HOME`.
- Do not run recursive delete or cleanup commands outside a clearly requested scope.
- Do not install packages, alter PATH, or change registry settings unless the
  task requires it.
- Homebase cleanup tasks can remove caches, temp files, recycle bin contents,
  and thumbnail caches; treat them as user-approved operations only.
- Preserve user changes in dirty files. Do not revert unrelated work.

## Documentation Maintenance

Update `README.md` and this file when workflows, paths, commands, or repository
boundaries change.

Do not copy old documentation blindly. Verify claims against tracked files,
Homebase source, or command output before documenting them.
