# AGENTS Instructions

This is a bare-Git dotfiles work tree rooted at `$HOME`. These instructions are
for AI assistants and automation working in this repository.

## Repository Map

- Work tree: `$HOME`
- Dotfiles Git directory: `~/.dotfiles`
- Dotfiles remote memory: `~/.dotfiles-repo`
- Homebase source: `~/.local/lib/homebase`
- Homebase binary: `~/.local/bin/hb.exe`

Use the bare repository form for dotfiles Git operations:

```powershell
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" status
```

The PowerShell profile defines the `dot` alias:

```powershell
New-Alias -Name dot -Value Invoke-Dot -ErrorAction SilentlyContinue

function Invoke-Dot {
  git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" @Args
}
```

## AI Workflow

1. Read `README.md`, `AGENTS.md`, and the files directly related to the task
2. Check dotfiles status with the bare repository command before editing
3. Treat Homebase as a separate Git repository at `~/.local/lib/homebase`
4. Keep edits scoped to the requested dotfile, Homebase config, or Homebase code
5. Run the smallest verification set that proves the change
6. Report commands that were run and any commands that could not be run

Do not scan or mutate unrelated personal files under `$HOME`. This repository is
a home-directory work tree, so untracked files outside configured paths are not
project files.

## Current Workflow

Homebase owns bootstrap, package installation, cleanup, and dotfiles sync:

```powershell
hb bootstrap
hb install
hb cleanup
hb sync
```

Use Homebase for routine synchronization:

```powershell
hb sync -m "chore: sync dotfiles"
```

Manual Git operations are acceptable when Homebase is unavailable:

```powershell
dot status
dot add README.md AGENTS.md .pwsh/profile.ps1
dot commit -m "docs: update dotfiles docs"
dot push origin main
```

## Behavioral Boundaries

- Do not restore the removed `installer/` workflow
- Do not recreate `installer/packages/scoop.txt`
- Do not recreate `installer/packages/winget.txt`
- Do not add bundled font directories as a package-management strategy
- Do not run `hb bootstrap`, `hb install`, `hb cleanup`, or package managers for
  verification unless the user explicitly asks for live side effects
- Do not modify `.config/nvim` or `.config/wezterm` internals unless the task is
  specifically about those submodules
- Do not touch existing Arch Linux Homebase behavior unless explicitly requested
- Do not run destructive Git commands such as `git reset --hard` or
  `git checkout --` unless the user explicitly asks for that operation
- Do not revert user changes in a dirty work tree

Prefer static inspection, tests, `--help` output, and fake-runner coverage over
commands that mutate the machine.

## Dotfiles Contents

Tracked dotfiles include:

- `.pwsh/profile.ps1`: PowerShell profile linked to PowerShell profile paths
- `.config/nvim`: Neovim config submodule
- `.config/wezterm`: WezTerm config submodule
- `.config/vscode-nvim`: VSCode Neovim settings
- `.config/visual-studio`: Visual Studio settings
- `.config/ssms`: SQL Server Management Studio settings
- `.config/opencode/opencode.jsonc`: opencode config
- `.starship/starship.toml`: Starship prompt config
- `.vimrc`, `.gitconfig`, `.gitignore`, `.gitattributes`, `.gitmodules`
- `.agents`: local Codex skills
- `README.md` and `AGENTS.md`

Use this command to list tracked paths:

```powershell
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" ls-files
```

## Homebase Config

Windows package, cleanup, and sync configuration lives in Homebase TOML:

```text
~/.config/homebase/platforms/windows/
~/.local/lib/homebase/config/platforms/windows/
```

Runtime config under `~/.config/homebase` controls this machine and may include
local untracked state. Defaults under `~/.local/lib/homebase/config` belong to
the Homebase repository.

Default Windows package groups are in:

```text
~/.local/lib/homebase/config/platforms/windows/packages.d/*.toml
```

Use TOML for package changes. Fonts are installed through Scoop config:

```toml
[fonts]
label = "Fonts"
scoop_buckets = ["nerd-fonts"]
scoop = ["FiraCode-NF"]
```

## Homebase Code Changes

Homebase is a separate Git repository at `~/.local/lib/homebase`.

When editing Homebase:

- Keep platform-specific behavior under `internal/platform/<id>`
- Keep Windows behavior under `internal/platform/windows`
- Keep runtime defaults under `config/platforms/windows`
- Keep command routing thin in `cmd/hb/main.go`
- Use `internal/run.Runner` for code that shells out
- Use `internal/testutil` for shared fakes
- Preserve existing TOML shapes unless the task requires a schema change

Run before finishing Homebase code changes:

```powershell
Set-Location ~/.local/lib/homebase
gofmt -w cmd internal
go test ./...
go vet ./...
go build -o ~/.local/bin/hb.exe ./cmd/hb
```

Run after Homebase README or Markdown changes:

```powershell
Set-Location ~/.local/lib/homebase
markdownlint-cli2 README.md AGENTS.md
```

## Dotfiles Verification

For docs-only changes in this dotfiles repository:

```powershell
markdownlint-cli2 README.md AGENTS.md
```

For PowerShell profile changes:

```powershell
$bytes = [System.IO.File]::ReadAllBytes("$HOME\.pwsh\profile.ps1")[0..2]
($bytes | ForEach-Object { $_.ToString("X2") }) -join " "
```

Expected output:

```text
EF BB BF
```

For Homebase command availability without machine mutation:

```powershell
& "$HOME\.local\bin\hb.exe" --help
```

## File Encoding

All `.ps1` files must be UTF-8 with BOM for Windows PowerShell 5.1.

Create or rewrite PowerShell files with:

```powershell
[System.IO.File]::WriteAllText(
  $path,
  $content,
  [System.Text.UTF8Encoding]::new($true)
)
```

Verify the first three bytes are:

```text
EF BB BF
```

Rewrite with BOM after editing if the marker is missing.

## Development Style

- Prefer existing Homebase, PowerShell, Lua, and TOML patterns over new
  abstractions
- Keep Windows-specific behavior in Windows-owned files
- Keep shared Homebase helpers policy-free and backed by at least two callers
- Keep documentation factual and grounded in repository files
- Use copyable command blocks for setup and verification commands
- Keep markdown headings concise and stable
- Avoid adding generated artifacts, package caches, logs, or local machine dumps

## Pull Requests And Bug Reports

Bug reports should include:

- Windows version and PowerShell version
- The `hb`, `dot`, or shell command that failed
- Relevant flags and config paths
- Expected behavior and actual output
- Whether runtime config or Homebase defaults were changed

Pull requests should:

- Explain the affected workflow
- Keep dotfiles and Homebase changes separated when practical
- Include verification output or explain why a command was skipped
- Avoid unrelated formatting churn
- Update README and AGENTS instructions when workflows or boundaries change
