# Windows Dotfiles

Guidelines for AI agents working in this Windows bare-repo dotfiles setup.

## Repo Layout

| Path | Purpose |
|---|---|
| `~` | Working tree (all tracked files at real paths) |
| `~/.dotfiles/` | Bare git repository |
| `~/.pwsh/profile.ps1` | PowerShell profile (symlinked to `$profile`) |
| `~/.starship/starship.toml` | Starship prompt config |
| `~/.config/` | Configs: Neovim, WezTerm, VSCode, VS, SSMS |
| `~/installer/` | bootstrap.ps1, install.ps1, cleanup.ps1, lib/, packages/, fonts/ |
| `~/installer/lib/` | Shared helpers (tui.ps1) |
| `~/dotfiles.ps1` | Sync helper: stage → commit → push |
| `~/.dotfiles-repo` | Memory file: SSH URL of the active remote |

## The `dot` Alias

Always use `dot` for git ops in `$HOME` — never plain `git`:

```powershell
function Invoke-Dot { git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" @Args }
New-Alias dot Invoke-Dot
```

## Core Scripts

**`dotfiles.ps1`** — sync tracked files: `.\dotfiles.ps1 [-Message "msg"] [-DryRun]`. Add files via `$TrackedPaths`.
**`installer/bootstrap.ps1`** — new machine setup: `.\installer\bootstrap.ps1 [-Repo <url>] [-Yes]`. Flags: `-Yes` (non-interactive), `-Repo <url>`, `-DotfilesDir <path>`. Uses `~/.dotfiles-repo` to remember remote.
**`installer/install.ps1`** — package installer: `.\installer\install.ps1 [-Unattended]`. Groups: Core, Scoop, Winget, Setup.
**`installer/cleanup.ps1`** — system cleanup: `.\installer\cleanup.ps1 [-Unattended]`. Tasks: scoop-cache, temp-files, npm-cache, winget-cache, recycle-bin, thumbnail-cache.
**TUI Convention**: All installer scripts use helpers from `installer/lib/tui.ps1`. See the **dotfiles-tui** skill.

## Git Operations

```powershell
dot status / diff          # check state
dot add <path>             # stage
dot commit -m "type(scope): description"    # commit
dot push origin main       # push
.\dotfiles.ps1 -Message "..."   # all-in-one
```

## Submodules

| Submodule | Path | Remote |
|---|---|---|
| nvchad | `.config/nvim` | `gin31259461/nvchad.git` (main) |
| wezterm | `.config/wezterm` | `gin31259461/wezterm.git` (main) |

```powershell
dot submodule update --init --recursive   # init
dot submodule update --remote --merge      # update
dot submodule sync --recursive             # sync
```

## Package Lists

`installer/packages/scoop.txt` (one per line), `installer/packages/winget.txt` (one ID per line). `#` lines ignored. Add: install → add to `.txt` → `.\dotfiles.ps1 -Message "chore: add <pkg>"`.

## PowerShell Profile

`~/.pwsh/profile.ps1` — symlinked to `$profile`. Key aliases: `dot` (bare-repo git), `v` (nvim), `k` (kubectl), `h` (helm), `g` (quick dir nav), `kn` (kubectl namespace). `g` shortcuts: `pr`→`~/projects`, `bp`→`~/projects/boilerplates`, `cs`→`~/projects/cheat-sheets`.

## File Encoding

All `.ps1` files **must** be UTF-8 with BOM (PowerShell 5.1 requirement). Create: `[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($true))`. Verify: check first 3 bytes are `EF BB BF`. Re-write with BOM if missing after editing.

## Commit Style

Lowercase imperative, no co-author trailers, always push: `feat(nvim): update keymaps`, `fix(profile): correct goto shortcut`, `refactor: extract tui helpers`, `docs: update new-machine steps`, `chore: add ripgrep to winget`.

## PowerShell Guidelines

See the **powershell-guidelines** skill for full coding conventions (naming, parameters, pipeline, error handling, documentation).

## Review Checklist

Before marking done:

1. **Re-read every changed file** — no debug lines, wrong indentation, stale references
2. **Run syntax checks** — AST parser on every `.ps1` touched: `[System.Management.Automation.Language.Parser]::ParseFile('path', [ref]$null, [ref]$errors) | Out-Null; $errors`
3. **Check related bugs** — search all call sites of renamed/removed functions
4. **Verify UTF-8 BOM** on every `.ps1` created or edited
5. **Verify consistency** — check docs, README, and "After Modifying" table
6. **Commit and push** — `dot add <files> && dot commit -m "type(scope): description" && dot push origin main` (or `.\dotfiles.ps1 -Message "..."`). Never leave unpushed.

## After Modifying Dotfiles

Update docs whenever scripts, features, or flags change. Commit all changes before marking done.

| What changed | What to update |
|---|---|
| New/updated/removed script/feature | `README.md` and/or `AGENTS.md` |
| New flag or option | `README.md` usage + script `.SYNOPSIS` |
| New/removed tracked file | `dotfiles.ps1` `$TrackedPaths` |
| TUI conventions changed | `AGENTS.md` + dotfiles-tui skill |
| Guidelines/workflow changed | `AGENTS.md` |
| `AGENTS.md` edited | Re-read after editing |
