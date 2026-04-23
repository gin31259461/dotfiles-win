#Requires -Version 5.1
<#
.SYNOPSIS
    Sync dotfiles to the remote repository.
.DESCRIPTION
    Stages all tracked paths, commits with a message, and pushes to origin main.
    Uses a bare git repository at ~/.dotfiles with $HOME as the work tree.

    When -Message is omitted an interactive prompt opens (Read-Host).
    Leave it empty to use the default message "sync dotfiles".
.PARAMETER Message
    Git commit message. Prompted interactively when not provided.
.PARAMETER DryRun
    Show what would be staged and committed without making any changes.
.EXAMPLE
    .\dotfiles.ps1
.EXAMPLE
    .\dotfiles.ps1 -Message "update nvim config"
.EXAMPLE
    .\dotfiles.ps1 -DryRun
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $Message = '',
    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\installer\lib\tui.ps1"

# ── Tracked paths ─────────────────────────────────────────────────────────────
$TrackedPaths = @(
    'README.md'
    '.dotfiles-repo'
    '.gitmodules'
    '.gitignore'
    '.gitattributes'
    '.gitconfig'
    '.github'
    'dotfiles.ps1'
    'installer'
    '.config/wezterm'
    '.config/visual-studio'
    '.config/vscode-nvim'
    '.config/ssms'
    '.config/nvim'
    '.pwsh'
    '.starship'
    '.vimrc'
)

function Invoke-Dot {
    git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" @Args
}

Set-Location $HOME

# ── Commit message ────────────────────────────────────────────────────────────

if (-not $Message) {
    Write-Host ""
    Write-Host "${BLU}?${RST}  Commit message  ${DIM}(empty = 'sync dotfiles')${RST}"
    Write-Host "  " -NoNewline
    $Message = Read-Host
    if (-not $Message) { $Message = 'sync dotfiles' }
}

# ── Dry run ───────────────────────────────────────────────────────────────────

if ($DryRun) {
    warn "Dry run — the following would be staged and committed:"
    Write-Host ""
    foreach ($path in $TrackedPaths) {
        $exists = Test-Path $path
        $suffix = if ($exists) { '' } else { '  (not found)' }
        note "  dot add $path$suffix"
    }
    note "  dot commit -m `"$Message`""
    note "  dot push origin main"
    Write-Host ""
    return
}

# ── Stage, commit, push ───────────────────────────────────────────────────────

section "Staging dotfiles"
foreach ($path in $TrackedPaths) {
    if (Test-Path $path) {
        Invoke-Dot add $path
        note "  + $path"
    } else {
        warn "Path not found, skipping: $path"
    }
}

Invoke-Spin "Committing: $Message" { Invoke-Dot commit -m $Message }
ok "Committed: $Message"

Invoke-Spin "Pushing to origin..." { Invoke-Dot push origin main }
ok "Pushed to origin main"
