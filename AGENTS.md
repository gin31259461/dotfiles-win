# AGENTS instructions

This is a bare-Git dotfiles work tree rooted at `$HOME`.

- Work tree: `$HOME`
- Git directory: `~/.dotfiles`
- Dotfiles remote memory: `~/.dotfiles-repo`
- Homebase source: `~/.local/lib/homebase`
- Homebase binary: `~/.local/bin/hb.exe`

Use the bare repo form for dotfiles Git operations:

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

## Current Workflow

Homebase owns bootstrap, package install, cleanup, and dotfiles sync.

```powershell
hb bootstrap
hb install
hb cleanup
hb sync
```

Do not restore the old `installer/` workflow. The old PowerShell scripts,
package text files, and bundled fonts were replaced by Homebase.

## Dotfiles Repo Contents

Tracked dotfiles include:

- `.pwsh/profile.ps1`: PowerShell profile, linked to PowerShell profile paths
- `.config/nvim`: Neovim config submodule
- `.config/wezterm`: WezTerm config submodule
- `.config/vscode-nvim`: VSCode Neovim settings
- `.config/visual-studio`: Visual Studio settings
- `.config/ssms`: SQL Server Management Studio settings
- `.config/opencode/opencode.jsonc`: opencode config
- `.starship/starship.toml`: Starship prompt config
- `.vimrc`, `.gitconfig`, `.gitignore`, `.gitattributes`, `.gitmodules`
- `README.md` and `AGENTS.md`

## Homebase Config

Windows package, cleanup, and sync configuration lives in Homebase TOML:

```text
~/.config/homebase/platforms/windows/
~/.local/lib/homebase/config/platforms/windows/
```

Default Windows package groups are in:

```text
~/.local/lib/homebase/config/platforms/windows/packages.d/*.toml
```

Use TOML for package changes. Do not recreate:

- `installer/packages/scoop.txt`
- `installer/packages/winget.txt`
- bundled font directories

Fonts are installed through Scoop config, currently with:

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
- Do not touch existing Arch Linux platform code unless explicitly requested
- Keep Windows behavior under `internal/platform/windows`
- Keep runtime defaults under `config/platforms/windows`
- Run `gofmt -w cmd internal`
- Run `go test ./...`
- Run `go vet ./...`
- Rebuild with `go build -o ~/.local/bin/hb.exe ./cmd/hb`
- Run `markdownlint-cli2 README.md` after README changes

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

## Syncing Changes

Prefer Homebase:

```powershell
hb sync -m "chore: sync dotfiles"
```

For manual Git operations:

```powershell
dot status
dot add README.md AGENTS.md .pwsh/profile.ps1
dot commit -m "docs: update dotfiles docs"
dot push origin main
```
