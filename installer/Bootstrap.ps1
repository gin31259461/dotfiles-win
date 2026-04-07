#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap dotfiles onto a new machine.
.DESCRIPTION
    Clones the dotfiles bare repository into ~/.dotfiles and copies all tracked
    files into $HOME using robocopy. Run this once on a fresh machine, then run
    Install.ps1 to install packages and set up features.
.PARAMETER RepoUrl
    SSH or HTTPS URL of the dotfiles repository.
    Default: git@github.com:gin31259461/dotfiles-win.git
.PARAMETER DotfilesDir
    Path for the bare git repository. Default: ~/.dotfiles
.EXAMPLE
    .\Bootstrap.ps1
.EXAMPLE
    .\Bootstrap.ps1 -RepoUrl 'https://github.com/yourname/dotfiles-win.git'
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $RepoUrl     = 'git@github.com:gin31259461/dotfiles-win.git',
    [string] $DotfilesDir = "$HOME/.dotfiles"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '  ╭─────────────────────────────────────────────╮' -ForegroundColor Cyan
Write-Host '  │          Dotfiles Bootstrap                 │' -ForegroundColor Cyan
Write-Host '  ╰─────────────────────────────────────────────╯' -ForegroundColor Cyan
Write-Host ''
Write-Host "  Repo:   $RepoUrl" -ForegroundColor DarkGray
Write-Host "  Target: $DotfilesDir" -ForegroundColor DarkGray
Write-Host ''

if (Test-Path $DotfilesDir) {
    Write-Warning "Dotfiles directory already exists: $DotfilesDir"
    Write-Host '  Remove it first or pass a different -DotfilesDir.' -ForegroundColor Yellow
    exit 1
}

$tmpDir = Join-Path $env:TEMP 'dotfiles-bootstrap'

Write-Host '  ● Cloning repository...' -ForegroundColor Cyan
git clone --separate-git-dir=$DotfilesDir $RepoUrl $tmpDir

Write-Host '  ● Copying files to home directory...' -ForegroundColor Cyan
robocopy $tmpDir $HOME /E /XD .git | Out-Null

Write-Host '  ● Cleaning up...' -ForegroundColor Cyan
Remove-Item -Path $tmpDir -Recurse -Force

Write-Host '  ● Configuring git...' -ForegroundColor Cyan
git --git-dir=$DotfilesDir --work-tree=$HOME config --local status.showUntrackedFiles no

Write-Host ''
Write-Host '  ✓ Dotfiles bootstrapped successfully!' -ForegroundColor Green
Write-Host ''
Write-Host '  Next steps:' -ForegroundColor Cyan
Write-Host '    1. Run .\Install.ps1 to install packages and set up features' -ForegroundColor White
Write-Host '    2. Run: dot submodule update --init --recursive' -ForegroundColor White
Write-Host '    3. Open a new terminal to load the PowerShell profile' -ForegroundColor White
Write-Host ''
