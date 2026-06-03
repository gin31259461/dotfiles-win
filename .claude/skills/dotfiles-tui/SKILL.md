---
name: dotfiles-tui
description: Conventions for the terminal TUI helpers in installer/lib/tui.ps1 — print helpers, confirmation prompts, loading spinners, and keyboard menus. Load when creating or editing installer scripts that use these helpers.
---

# Dotfiles TUI Convention

All installer scripts share a common visual language via `~/installer/lib/tui.ps1` — always dot-source it at the top of new scripts.

## When to Use

- Creating a new script under `installer/` that needs UI output
- Adding a new menu item to `install.ps1` or `cleanup.ps1`
- Writing a script that needs confirmation prompts or loading indicators
- Reviewing or editing `tui.ps1` itself

## When Not to Use

- Scripts that produce machine-readable output (JSON, CSV)
- Scripts that don't interact with a user

## Usage

Dot-source the library:

```powershell
. "$PSScriptRoot\lib\tui.ps1"              # from installer/ scripts
. "$PSScriptRoot\installer\lib\tui.ps1"   # from dotfiles.ps1 at $HOME
```

## Print Helpers

All output starts at column 0 (no left padding). `section` adds blank lines before and after.

Available colour variables: `$RED $GRN $YLW $BLU $DIM $BOLD $RST` (ANSI, enabled on load).

```powershell
die     "fatal message"       # "✗  message" — exits with code 1
ok      "success message"     # "✔  message" — green
warn    "warning message"     # "!  message" — yellow
note    "dim message"         # dim text
step    "in-progress message" # "›  message" — blue
section "Heading"             # newline + "◆  Heading" (bold blue) + newline
```

### Invoke-Confirm — confirmation prompt

```powershell
if (Invoke-Confirm "Question?") { … }   # "?  Question?  [y/N]"
```

Returns `$true` (y/yes) or `$false`. Wrap with a local `confirm` function that checks a `-Yes`/`-Unattended` flag:

```powershell
function confirm {
    param([string]$Question)
    if ($Yes) { return $true }
    return Invoke-Confirm $Question
}
```

### Invoke-Spin — loading indicator

Prints a `step` line then executes a scriptblock with a spinner.

```powershell
Invoke-Spin "Cloning repo…"    { git clone $url $dest }
Invoke-Spin "Installing pkgs…" { scoop install $pkg }
```

### Start-TuiMenu — keyboard selection menu

```powershell
$result = Start-TuiMenu -Items $items `
    -Title  'My Menu' `
    -Footer '  ↑↓ Navigate   Space Toggle   A Select All   N Deselect   Enter Confirm   Q Quit'

if ($null -eq $result) { exit 0 }
$selected = $result | Where-Object Selected
```

Each item is a `PSCustomObject` with at minimum `Name` (string) and `Selected` (bool). Optional fields: `Description` (right-side detail), `Group` (section heading), `Hint` (short label, e.g. disk size), `HintColor` (ANSI colour string).

## Validation

- [ ] `tui.ps1` is dot-sourced at the top of the script (not after other logic)
- [ ] Output uses provided helpers (`ok`, `warn`, `step`, etc.) not raw `Write-Host`
- [ ] Confirmations use `Invoke-Confirm` wrapped with a `-Yes`/`-Unattended` guard
- [ ] Long-running operations use `Invoke-Spin`
- [ ] Menu items use correct `PSCustomObject` shape
