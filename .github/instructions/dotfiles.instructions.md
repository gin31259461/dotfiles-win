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
| `~/.pwsh/profile.ps1` | PowerShell profile (symlinked to `$profile` by install.ps1) |
| `~/.starship/starship.toml` | Starship prompt config |
| `~/.config/nvim/` | Neovim config — git submodule (gin31259461/nvchad) |
| `~/.config/wezterm/` | WezTerm config — git submodule (gin31259461/wezterm) |
| `~/.config/vscode-nvim/` | VSCode Neovim extension keybindings |
| `~/.config/visual-studio/` | Visual Studio exported settings |
| `~/.config/ssms/` | SQL Server Management Studio settings |
| `~/installer/` | bootstrap.ps1, install.ps1, cleanup.ps1, lib/, packages/, fonts/ |
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

### `installer/bootstrap.ps1` — new machine setup

Full one-command setup on a fresh Windows machine:

```powershell
# Download and run directly:
irm https://raw.githubusercontent.com/gin31259461/dotfiles-win/main/installer/bootstrap.ps1 | iex

# Or from a local clone:
.\installer\bootstrap.ps1
.\installer\bootstrap.ps1 -Repo 'git@github.com:you/dotfiles-win.git'
.\installer\bootstrap.ps1 -Yes   # non-interactive, accept all defaults
```

Flags:
- `-Yes` — non-interactive, skip optional prompts
- `-Repo <url>` — SSH URL of your fork (`user/repo` shorthand accepted)
- `-DotfilesDir <path>` — custom bare repo location (default: `~/.dotfiles`)

What it does: checks git → clones repo → robocopy deploys to `$HOME` →
configures `dot` → inits submodules → optional `install.ps1`.

**Repo selection (memory file `~/.dotfiles-repo`):**

`bootstrap.ps1` writes `~/.dotfiles-repo` after every successful clone to
remember which SSH remote URL this machine uses. The file is **tracked in the
repo** so it is deployed to every new machine via robocopy.

`$DefaultRepoSsh`/`$DefaultRepoHttps` are overridden at startup from
`~/.dotfiles-repo` (if it exists), so the correct fork is targeted without
any flags.

| Condition | Action |
|---|---|
| No `-Repo`, memory file present | SSH clone from that URL (HTTPS fallback if no key) |
| `-Repo` differs from effective default | HTTPS clone of the default repo as base; set `-Repo` URL as `origin`; **bake fork URL into deployed `bootstrap.ps1`** so future machines need no flag |

**Fork owner workflow:**
1. First machine: `bootstrap.ps1 -Repo git@github.com:you/dotfiles-win.git`
   → clones default, sets remote, bakes your URL into `bootstrap.ps1`, writes `~/.dotfiles-repo`
2. Run `dotfiles.ps1` to commit and push (both `bootstrap.ps1` and `.dotfiles-repo` are tracked)
3. All subsequent machines: run from your fork's URL — no `-Repo` needed

### `installer/install.ps1` — interactive package installer

Keyboard-navigable TUI installer for packages and features.

```powershell
.\installer\install.ps1              # interactive TUI
.\installer\install.ps1 -Unattended  # install everything silently
```

TUI controls: `↑↓` navigate · `Space` toggle · `A` select all · `N` deselect · `Enter` install · `Q`/`Esc` quit.

| Group | What it installs |
|---|---|
| Core | Scoop, PowerShell 7+, PSReadLine, Node.js + pnpm |
| Scoop Packages | Each line in `packages/scoop.txt` |
| Winget Packages | Each line in `packages/winget.txt` |
| Setup | Fonts, profile symlink, WezTerm context menu, Win10 classic menu |

To add a new installer item, add a `New-MenuItem` call inside `Get-MenuItems` in `install.ps1`.

### `installer/cleanup.ps1` — interactive system cleanup

Frees disk space: Scoop cache, Temp folder, npm cache, WinGet cache, Recycle Bin, thumbnail cache.
Shows reclaimable size before confirming.

```powershell
.\installer\cleanup.ps1              # interactive TUI (keyboard menu, same controls as install.ps1)
.\installer\cleanup.ps1 -Unattended  # skip confirmations, run all tasks
```

Each task shows reclaimable disk space (colour-coded) before anything is deleted.
TUI controls: `↑↓` navigate · `Space` toggle · `A` select all · `N` deselect · `Enter` confirm · `Q`/`Esc` quit.

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

### `Start-TuiMenu` — keyboard selection menu

```powershell
$result = Start-TuiMenu -Items $items `
    -Title  'My Menu' `
    -Footer '  ↑↓ Navigate   Space Toggle   A Select All   N Deselect   Enter Confirm   Q Quit'

if ($null -eq $result) { exit 0 }           # user pressed Q / Esc
$selected = $result | Where-Object Selected  # filter chosen items
```

Each item is a `PSCustomObject` with at minimum `Name` (string) and `Selected` (bool).
Optional fields: `Description` (right-side detail), `Group` (section heading), `Hint`
(short label, e.g. disk size), `HintColor` (ANSI colour string for the hint).

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

Source: `~/.pwsh/profile.ps1` — symlinked to `$profile` by `install.ps1`.

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

When **creating** a `.ps1` file via a tool or script, always write it with BOM:

```powershell
$utf8bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($path, $content, $utf8bom)
```

When **editing** an existing `.ps1` file, verify the encoding is preserved
(the file should begin with the byte sequence `EF BB BF`):

```powershell
$bytes = [System.IO.File]::ReadAllBytes($path)
if ($bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
    Write-Warning "$path is missing UTF-8 BOM — re-save with BOM"
}
```

> **Copilot rule**: After creating or editing any `.ps1` file, verify the BOM is
> present. If the editing tool does not preserve it, re-write the file with the
> `[System.IO.File]::WriteAllText` method above.

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
- **Always push after committing** — `dot push origin main`. Never leave commits unpushed at task end.
- Prefer atomic commits (one logical change per commit)
- Pass a descriptive `-Message` to `dotfiles.ps1` — avoid generic `"sync dotfiles"`

---

## Review Before Completing

Before marking any task done, always work through every step below:

1. **Re-read every file you changed** — check for leftover debug lines, wrong
   indentation, missed substitutions, or stale references.

2. **Run syntax checks** — use the PowerShell AST parser (no script execution needed):
   ```powershell
   $errors = $null
   [System.Management.Automation.Language.Parser]::ParseFile(
       'C:\path\to\script.ps1', [ref]$null, [ref]$errors) | Out-Null
   $errors   # empty = clean
   ```
   Run this for every `.ps1` file you created or modified.

3. **Check for related bugs** — search all call sites of any function or variable
   you renamed/removed/changed. If `tui.ps1` helpers were touched, check every
   script that dot-sources it.

4. **Verify UTF-8 BOM** — for every `.ps1` file created or edited, confirm the
   BOM is present:
   ```powershell
   $b = [System.IO.File]::ReadAllBytes('C:\path\to\file.ps1')
   if ($b[0] -ne 0xEF -or $b[1] -ne 0xBB -or $b[2] -ne 0xBF) {
       Write-Warning 'Missing UTF-8 BOM — re-save the file'
   }
   ```
   If the BOM is missing, re-write with `[System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding $true))`.

5. **Verify consistency** — confirm that docs, instructions, and README still
   accurately describe the changed code. Check the "After Modifying Dotfiles"
   table below and update everything that applies.

6. **Commit and push** — stage changed files, commit with a descriptive message,
   then push:
   ```powershell
   dot add <files...>
   dot commit -m "type(scope): description"
   dot push origin main
   ```
   Or use `.\dotfiles.ps1 -Message "..."` which does all three.
   **Never leave a completed task without pushing to origin.**

Only mark a task complete after all six steps pass.

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
| Guidelines or workflow changed | `dotfiles.instructions.md` — update the relevant section |
| Instructions file itself | Re-read after editing to confirm accuracy |

After updating any of the above, **commit and push all changes**:

```powershell
# Commit and push individual files manually:
dot add <changed files...>
dot commit -m "docs: ..."
dot push origin main

# Or use the sync helper (stages all tracked paths):
.\dotfiles.ps1 -Message "docs: ..."
```

Both tracked dotfiles (`.github/`, `installer/`) and documentation changes
must be committed in the same session — never leave them pending.
