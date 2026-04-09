---
applyTo: '**'
description: 'Guidelines for managing this Windows bare-repo dotfiles setup.'
---

# Dotfiles Management Guidelines

## Repository Layout

These dotfiles are managed with a **bare git repository** — no symlinks, no
stow. The working tree is `$HOME`; config files live at their real paths.

| Path | Purpose |
|---|---|
| `~/.dotfiles/` | Bare git repository |
| `~` | Working tree (all tracked files live here directly) |
| `~/.pwsh/profile.ps1` | PowerShell profile (symlinked to `$profile` by Install.ps1) |
| `~/.starship/starship.toml` | Starship prompt config |
| `~/.config/nvim/` | Neovim config — git submodule (gin31259461/nvchad) |
| `~/.config/wezterm/` | WezTerm config — git submodule (gin31259461/wezterm) |
| `~/.config/vscode-nvim/` | VSCode Neovim extension keybindings |
| `~/.config/visual-studio/` | Visual Studio exported settings |
| `~/.config/ssms/` | SQL Server Management Studio settings |
| `~/installer/` | Bootstrap.ps1, Install.ps1, cleanup.ps1, lib/, packages/, fonts/ |
| `~/installer/lib/tui.ps1` | Shared TUI helpers — dot-sourced by all scripts |
| `~/dotfiles.ps1` | Sync helper: stage → commit → push |
| `~/.dotfiles-repo` | Memory file: SSH URL of the active dotfiles remote |
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

## Core Scripts

### `dotfiles.ps1` — sync changes to the repo

Stages all tracked paths, commits, and pushes to `origin main`.

```powershell
.\dotfiles.ps1                         # interactive prompt for commit message
.\dotfiles.ps1 -Message "update hypr"  # skip prompt, use provided message
.\dotfiles.ps1 -DryRun                 # preview without committing
```

When `-Message` is omitted, a `Read-Host` prompt opens. Leave it empty to
fall back to `"sync dotfiles"`.

To add a new file to tracking: add it to `$TrackedPaths` in `~/dotfiles.ps1`,
then run `dotfiles.ps1`.

### `installer/Bootstrap.ps1` — new machine setup

Full one-command setup on a fresh Windows machine:

```powershell
# Download and run directly:
irm https://raw.githubusercontent.com/gin31259461/dotfiles-win/main/installer/Bootstrap.ps1 | iex

# Or from a local clone:
.\installer\Bootstrap.ps1
.\installer\Bootstrap.ps1 -Repo 'git@github.com:you/dotfiles-win.git'
.\installer\Bootstrap.ps1 -Yes   # non-interactive, accept all defaults
```

Flags:
- `-Yes` — non-interactive, skip optional prompts
- `-Repo <url>` — SSH URL of your fork (`user/repo` shorthand accepted)
- `-DotfilesDir <path>` — custom bare repo location (default: `~/.dotfiles`)

What it does: checks git → clones repo → robocopy deploys to `$HOME` →
configures `dot` → inits submodules → optional `Install.ps1`.

**Repo selection (memory file `~/.dotfiles-repo`):**

`Bootstrap.ps1` writes `~/.dotfiles-repo` after every successful clone to
remember which SSH remote URL this machine uses. The file is **tracked in the
repo** so it is deployed to every new machine via robocopy.

`$DefaultRepoSsh`/`$DefaultRepoHttps` are overridden at startup from
`~/.dotfiles-repo` (if it exists), so the correct fork is targeted without
any flags.

| Condition | Action |
|---|---|
| No `-Repo`, memory file present | SSH clone from that URL (HTTPS fallback if no key) |
| `-Repo` differs from effective default | HTTPS clone of the default repo as base; set `-Repo` URL as `origin`; **bake fork URL into deployed `Bootstrap.ps1`** so future machines need no flag |

**Fork owner workflow:**
1. First machine: `Bootstrap.ps1 -Repo git@github.com:you/dotfiles-win.git`
   → clones default, sets remote, bakes your URL into `Bootstrap.ps1`, writes `~/.dotfiles-repo`
2. Run `dotfiles.ps1` to commit and push (both `Bootstrap.ps1` and `.dotfiles-repo` are tracked)
3. All subsequent machines: run from your fork's URL — no `-Repo` needed

### `installer/Install.ps1` — interactive package installer

Keyboard-navigable TUI installer for packages and features.

```powershell
.\installer\Install.ps1              # interactive TUI
.\installer\Install.ps1 -Unattended  # install everything silently
```

TUI controls: `↑↓` navigate · `Space` toggle · `A` select all · `N` deselect · `Enter` install · `Q`/`Esc` quit.

| Group | What it installs |
|---|---|
| Core | Scoop, PowerShell 7+, PSReadLine, Node.js + pnpm |
| Scoop Packages | Each line in `packages/scoop.txt` |
| Winget Packages | Each line in `packages/winget.txt` |
| Setup | Fonts, profile symlink, WezTerm context menu, Win10 classic menu |

To add a new installer item, add a `New-MenuItem` call inside `Get-MenuItems` in `Install.ps1`.

### `installer/cleanup.ps1` — interactive system cleanup

Frees disk space: Scoop cache, Temp folder, npm cache, WinGet cache, Recycle Bin, thumbnail cache.
Shows reclaimable size before confirming.

```powershell
.\installer\cleanup.ps1              # interactive (numbered task selection)
.\installer\cleanup.ps1 -Unattended  # skip confirmations
```

| Key | Task |
|---|---|
| `scoop-cache` | Scoop download cache (`scoop cache rm *`) |
| `temp-files` | `%TEMP%\*` — build artefacts, installers |
| `npm-cache` | `npm cache clean --force` |
| `winget-cache` | WinGet LocalCache + `%TEMP%\WinGet` |
| `recycle-bin` | `Clear-RecycleBin -Force` |
| `thumbnail-cache` | Explorer `thumbcache_*.db` — rebuilds on demand |

---

## TUI Style Convention

All scripts share the same visual language via **`~/installer/lib/tui.ps1`** —
dot-source it at the top of any new script:

```powershell
. "$PSScriptRoot\lib\tui.ps1"              # from installer/ scripts
. "$PSScriptRoot\installer\lib\tui.ps1"   # from dotfiles.ps1 at $HOME
```

### Print helpers

No left padding — all output starts at column 0. `section` adds a blank line
before and after the heading. `Invoke-Confirm` prints a blank line before the
prompt for top margin.

```powershell
# Colour variables: $RED $GRN $YLW $BLU $DIM $BOLD $RST  (ANSI, enabled on load)

die     "fatal message"       # "✗  message" — exits with code 1
ok      "success message"     # "✔  message" — green
warn    "warning message"     # "!  message" — yellow
note    "dim message"         # dim text
step    "in-progress message" # "›  message" — blue
section "Heading"             # newline + "◆  Heading" (bold blue) + newline
```

### `Invoke-Confirm` — confirmation prompt

```powershell
if (Invoke-Confirm "Question?") { ... }   # "?  Question?  [y/N]"
```

Returns `$true` (y/yes) or `$false`. Prints a blank line before the prompt.
Scripts with a `-Yes`/`-Unattended` flag check it before calling:

```powershell
function confirm {
    param([string]$Question)
    if ($Yes) { return $true }
    return Invoke-Confirm $Question
}
```

### `Invoke-Spin` — loading indicator

```powershell
Invoke-Spin "Cloning repo..."    { git clone $url $dest }
Invoke-Spin "Installing pkgs..." { scoop install $pkg }
```

Prints a `step` line then executes the scriptblock. Use for any operation
that may take several seconds.

---

## Git Operations

```powershell
# Status / diff
dot status
dot diff

# Stage a specific file
dot add .config/nvim
dot add .pwsh/profile.ps1

# Commit manually
dot commit -m "feat(nvim): update keymaps"

# Push
dot push origin main

# Sync everything at once (runs dotfiles.ps1)
.\dotfiles.ps1 -Message "your message"

# Recent history
dot log --oneline -10
```

**Always use `dot`, never plain `git` in `$HOME`.**

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

# Sync .gitmodules changes
dot submodule sync --recursive
```

**Do not `dot add` inside a submodule directory** — manage submodule content via their own repos.

---

## Package Lists

`installer/packages/scoop.txt` — one Scoop package name per line.
`installer/packages/winget.txt` — one winget package ID per line.
Lines starting with `#` are ignored.

To add a scoop package:
1. `scoop install <package>`
2. Add `<package>` to `~/installer/packages/scoop.txt`
3. `.\dotfiles.ps1 -Message "chore: add <package> to scoop packages"`

To add a winget package:
1. `winget search <name>` to find the ID
2. Add the ID to `~/installer/packages/winget.txt`
3. `.\dotfiles.ps1 -Message "chore: add <package> to winget packages"`

---

## PowerShell Profile

Source: `~/.pwsh/profile.ps1` — symlinked to `$profile` by `Install.ps1`.

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

PSReadLine: history-based prediction, Vim-style `Ctrl+h`/`Ctrl+k` navigation.

Starship: `$ENV:STARSHIP_CONFIG = "$HOME\.starship\starship.toml"`

---

## File Encoding

**All `.ps1` files must be saved as UTF-8 with BOM.** PowerShell 5.1 requires
this to correctly parse non-ASCII characters (Unicode icons in TUI, box-drawing
chars, etc.).

```powershell
$utf8bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($path, $content, $utf8bom)
```

---

## Commit Style

Use **lowercase imperative** subject lines. No co-author trailers.

```
feat(nvim): update keymaps
fix(profile): correct goto shortcut
refactor: extract tui helpers to lib/tui.ps1
docs: update README new-machine steps
chore: add ripgrep to winget packages
style: align installer menu columns
```

- **No co-authored-by trailers** — never append them
- Use `dot commit` not `git commit` for dotfiles
- Prefer atomic commits (one logical change per commit)
- Pass a descriptive `-Message` to `dotfiles.ps1` — avoid generic `"sync dotfiles"`

---

## Review Before Completing

Before marking any task done, always:

1. **Re-read every file you changed** — check for leftover debug lines, wrong indentation, missed substitutions, or stale references
2. **Run syntax checks** — `powershell -NoProfile -NonInteractive -Command "& { . .\path\to\script.ps1 }"` to catch parse errors
3. **Look for related bugs** — if you changed a helper used by multiple scripts, check all call sites
4. **Verify consistency** — confirm that docs, instructions, and README still accurately describe the code

Only call a task complete after this review passes.

---

## After Modifying Dotfiles

**You must update `README.md` and/or the instructions file whenever you add,
update, or remove any script, feature, or flag.** Never mark a task complete
without syncing docs.

| What changed | What to update |
|---|---|
| New script or feature added | `README.md` — add description to the relevant section |
| Existing script or feature updated | `README.md` and/or instructions — reflect the change |
| Script or feature removed | `README.md` and/or instructions — remove stale entries |
| New flag or option added | `README.md` (usage table/examples) and script `.SYNOPSIS` |
| New file added to dotfiles tracking | `dotfiles.ps1` — add to `$TrackedPaths` |
| Dotfiles file removed from tracking | `dotfiles.ps1` — remove from `$TrackedPaths` |
| TUI conventions changed | `dotfiles.instructions.md` — update TUI Style Convention |
| Instructions file itself | Re-read after editing to confirm accuracy |

Always run `dotfiles.ps1` after updating any of the above.
