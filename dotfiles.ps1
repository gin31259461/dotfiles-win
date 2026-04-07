<#
.SYNOPSIS
    Sync dotfiles to the remote repository.
.DESCRIPTION
    Stages all tracked paths, commits with a message, and pushes to origin.
    Uses a bare git repository at ~/.dotfiles with $HOME as the work tree.
.PARAMETER Message
    Git commit message. Default: 'sync dotfiles'
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
    [string] $Message = 'sync dotfiles',
    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Paths tracked by the bare git dotfiles repo
$TrackedPaths = @(
    'README.md'
    '.gitmodules'
    '.gitignore'
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

if ($DryRun) {
    Write-Host 'Dry run — the following would be staged and committed:' -ForegroundColor Yellow
    Write-Host ''
    foreach ($path in $TrackedPaths) {
        $exists = Test-Path $path
        $status = if ($exists) { '' } else { '  (not found)' }
        Write-Host "  dot add $path$status" -ForegroundColor $(if ($exists) { 'DarkGray' } else { 'DarkYellow' })
    }
    Write-Host "  dot commit -m `"$Message`"" -ForegroundColor DarkGray
    Write-Host '  dot push origin main' -ForegroundColor DarkGray
    Write-Host ''
    return
}

Write-Host 'Staging dotfiles...' -ForegroundColor Cyan
foreach ($path in $TrackedPaths) {
    if (Test-Path $path) {
        Invoke-Dot add $path
    } else {
        Write-Warning "Path not found, skipping: $path"
    }
}

Write-Host "Committing: $Message" -ForegroundColor Cyan
Invoke-Dot commit -m $Message

Write-Host 'Pushing to origin...' -ForegroundColor Cyan
Invoke-Dot push origin main

Write-Host 'Done.' -ForegroundColor Green
